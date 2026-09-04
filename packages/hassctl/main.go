package main

import (
	"bytes"
	"crypto/subtle"
	"embed"
	"encoding/json"
	"html/template"
	"log"
	"net/http"
	"sort"
	"time"

	"github.com/yuin/goldmark"
)

//go:embed README.md
var readmeMD []byte

//go:embed openapi.yaml
var openapiYAML []byte

//go:embed templates/*.html
var templatesFS embed.FS

// mustRead loads an embedded file; the set is fixed at build time, so a
// missing file is a programming error (panic at startup).
func mustRead(name string) []byte {
	b, err := templatesFS.ReadFile(name)
	if err != nil {
		panic("hassctl: embedded file " + name + ": " + err.Error())
	}
	return b
}

// server carries the resolved config and wires it into the HTTP handlers.
type server struct {
	cfg    *Config
	readme []byte // README.md rendered to HTML (static part, see newServer)
}

func newServer(cfg *Config) *server {
	return &server{cfg: cfg, readme: renderReadme()}
}

// renderReadme converts the embedded README.md to HTML. On an (impossible)
// parse error it degrades to escaped plain text.
func renderReadme() []byte {
	var buf bytes.Buffer
	if err := goldmark.Convert(readmeMD, &buf); err != nil {
		return []byte("<pre>" + template.HTMLEscapeString(string(readmeMD)) + "</pre>")
	}
	return buf.Bytes()
}

func (s *server) authorize(r *http.Request) bool {
	if s.cfg.Token == "" {
		return false
	}
	return subtle.ConstantTimeCompare(
		[]byte(r.Header.Get("X-Token")), []byte(s.cfg.Token),
	) == 1
}

// ---------------------------------------------------------------------------
// JSON API — every /api response is application/json with the same envelope:
//
//	success: {"ok": true, ...}
//	error:   {"ok": false, "error": {"code": ..., "message": ...}}
// ---------------------------------------------------------------------------

type apiError struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

type errorResponse struct {
	OK    bool     `json:"ok"`
	Error apiError `json:"error"`
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(v)
}

func writeErr(w http.ResponseWriter, status int, code, msg string) {
	writeJSON(w, status, errorResponse{OK: false, Error: apiError{Code: code, Message: msg}})
}

// deviceJSON is the machine-readable representation of a device.
func (s *server) deviceJSON(id, state string) map[string]any {
	d := s.cfg.Devices[id]
	return map[string]any{
		"mac":      d.MAC.String(), // "" when not configured
		"state":    state,
		"wake":     len(d.MAC) > 0,
		"poweroff": d.Poweroff.Addr != "",
	}
}

// handleDevices implements GET /api/devices.
func (s *server) handleDevices(w http.ResponseWriter, r *http.Request) {
	devices := make(map[string]any, len(s.cfg.Devices))
	for id, st := range s.deviceStates() {
		devices[id] = s.deviceJSON(id, st)
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "devices": devices})
}

// handleDevice implements GET /api/devices/{id}.
func (s *server) handleDevice(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if _, ok := s.cfg.Devices[id]; !ok {
		writeErr(w, http.StatusNotFound, "not_found", "unknown device: "+id)
		return
	}
	state := "off"
	if s.cfg.Devices[id].Status != "" && up(s.cfg.Devices[id].Status) {
		state = "on"
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "device": s.deviceJSON(id, state)})
}

// handleWake implements POST /api/devices/{id}/wake.
func (s *server) handleWake(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	d, ok := s.cfg.Devices[id]
	if !ok {
		writeErr(w, http.StatusNotFound, "not_found", "unknown device: "+id)
		return
	}
	if len(d.MAC) == 0 {
		writeErr(w, http.StatusBadRequest, "bad_request", "no MAC configured for "+id)
		return
	}
	if err := sendWake(d.MAC, d.Wake); err != nil {
		log.Printf("wake %s from %s: %v", id, r.RemoteAddr, err)
		writeErr(w, http.StatusInternalServerError, "internal", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true})
}

// handlePoweroff implements POST /api/devices/{id}/off.
func (s *server) handlePoweroff(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	d, ok := s.cfg.Devices[id]
	if !ok {
		writeErr(w, http.StatusNotFound, "not_found", "unknown device: "+id)
		return
	}
	if d.Poweroff.Addr == "" {
		writeErr(w, http.StatusBadRequest, "bad_request", "no poweroff configured for "+id)
		return
	}
	if err := poweroff(d); err != nil {
		log.Printf("off %s from %s: %v", id, r.RemoteAddr, err)
		writeErr(w, http.StatusInternalServerError, "internal", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true})
}

// deviceStates returns the live state of every configured device.
func (s *server) deviceStates() map[string]string {
	state := make(map[string]string, len(s.cfg.Devices))
	ids := make([]string, 0, len(s.cfg.Devices))
	for id := range s.cfg.Devices {
		ids = append(ids, id)
	}
	sort.Strings(ids)
	for _, id := range ids {
		if s.cfg.Devices[id].Status != "" && up(s.cfg.Devices[id].Status) {
			state[id] = "on"
		} else {
			state[id] = "off"
		}
	}
	return state
}

// pageData feeds the / page template. The readme is pre-rendered HTML from
// goldmark (trusted embedded content), so it is typed template.HTML to
// prevent double-escaping.
type pageData struct {
	Readme template.HTML
}

// pageTmpl is templates/page.html, embedded and parsed at init.
var pageTmpl = template.Must(template.ParseFS(templatesFS, "templates/page.html"))

// handlePage renders the README as HTML at /. It is public (no token): the
// page is documentation only, never device state — that lives behind auth at
// /api/devices.
func (s *server) handlePage(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	if err := pageTmpl.Execute(w, pageData{Readme: template.HTML(s.readme)}); err != nil {
		log.Printf("render page: %v", err)
	}
}

// serveBytes writes embedded content with an explicit content type. All of
// these are static, embedded assets; no-store is fine (they change with the
// binary, not with the content).
func serveBytes(w http.ResponseWriter, data []byte, contentType string) {
	w.Header().Set("Content-Type", contentType)
	w.Header().Set("X-Content-Type-Options", "nosniff")
	w.Header().Set("Cache-Control", "no-store")
	w.Write(data)
}

// handleSpec implements GET /openapi.yaml (public, consumed by the ReDoc page).
func (s *server) handleSpec(w http.ResponseWriter, r *http.Request) {
	serveBytes(w, openapiYAML, "application/yaml; charset=utf-8")
}

// docsHTML is the ReDoc page served at /docs (templates/docs.html): it loads
// the standalone bundle from the pinned CDN version and points it at the
// spec served by handleSpec. Only the JS comes from the CDN — the spec
// itself is served locally.
var docsHTML = mustRead("templates/docs.html")

// handleDocs implements GET /docs (public): interactive ReDoc documentation
// for the API.
func (s *server) handleDocs(w http.ResponseWriter, r *http.Request) {
	serveBytes(w, docsHTML, "text/html; charset=utf-8")
}

// handler returns the routed HTTP handler with auth enforced at the boundary
// (before method matching, so unauthenticated callers can't probe which
// endpoints exist). Split out of main so tests can exercise it via httptest.
func (s *server) handler() http.Handler {
	// public: documentation only (README page, ReDoc UI, spec)
	public := http.NewServeMux()
	public.HandleFunc("GET /{$}", s.handlePage)
	public.HandleFunc("GET /docs", s.handleDocs)
	public.HandleFunc("GET /openapi.yaml", s.handleSpec)

	// everything else is token-protected and speaks JSON
	api := http.NewServeMux()
	api.HandleFunc("GET /api/devices", s.handleDevices)
	api.HandleFunc("GET /api/devices/{id}", s.handleDevice)
	api.HandleFunc("POST /api/devices/{id}/wake", s.handleWake)
	api.HandleFunc("POST /api/devices/{id}/off", s.handlePoweroff)

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/", "/docs", "/openapi.yaml":
			public.ServeHTTP(w, r)
			return
		}
		if !s.authorize(r) {
			writeErr(w, http.StatusUnauthorized, "unauthorized", "bad or missing X-Token header")
			return
		}
		api.ServeHTTP(w, r)
	})
}

func main() {
	log.SetPrefix("hassctl: ")

	cfg, err := loadConfig(defaultConfigPath())
	if err != nil {
		log.Fatal(err)
	}
	if len(cfg.Devices) == 0 {
		log.Printf("warning: no devices configured")
	}
	for id, d := range cfg.Devices {
		log.Printf("device %s: mac=%v status=%s poweroff=%s", id, d.MAC, d.Status, d.Poweroff.Addr)
	}

	s := newServer(cfg)
	srv := &http.Server{
		Addr:              cfg.Listen,
		Handler:           s.handler(),
		ReadHeaderTimeout: 10 * time.Second,
	}
	log.Printf("listening on %s", cfg.Listen)
	log.Fatal(srv.ListenAndServe())
}
