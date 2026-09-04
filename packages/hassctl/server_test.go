package main

import (
	"crypto/ed25519"
	"crypto/rand"
	"encoding/json"
	"encoding/pem"
	"errors"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"golang.org/x/crypto/ssh"
)

// testConfig writes a config file with all endpoints pointed at loopback so
// the tests never touch the real network: the wake packet goes to 127.0.0.1:9
// (harmless UDP datagram), and status/poweroff target a closed port.
func testConfig(t *testing.T) *Config {
	t.Helper()

	dir := t.TempDir()
	keyPath := filepath.Join(dir, "poweroff-key")
	_, priv, err := ed25519.GenerateKey(rand.Reader)
	if err != nil {
		t.Fatal(err)
	}
	block, err := ssh.MarshalPrivateKey(priv, "")
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(keyPath, pem.EncodeToMemory(block), 0o600); err != nil {
		t.Fatal(err)
	}

	path := filepath.Join(dir, "config.yaml")
	content := `
token: "testtoken"
listen: "127.0.0.1:0"
wake:
  localAddr: "127.0.0.1"
  broadcast: "127.0.0.1"
poweroff:
  user: "test"
  sshKey: "` + keyPath + `"
devices:
  jupiter:
    mac: "00:11:22:33:44:55"
    status: "127.0.0.1:1"
    poweroff:
      addr: "127.0.0.1:1"
  nomac:
    status: "127.0.0.1:1"
`
	if err := os.WriteFile(path, []byte(content), 0o600); err != nil {
		t.Fatal(err)
	}
	cfg, err := loadConfig(path)
	if err != nil {
		t.Fatal(err)
	}
	return cfg
}

type apiErr struct {
	OK    bool `json:"ok"`
	Error struct {
		Code    string `json:"code"`
		Message string `json:"message"`
	} `json:"error"`
}

func TestServerEndpoints(t *testing.T) {
	ts := httptest.NewServer(newServer(testConfig(t)).handler())
	defer ts.Close()

	token := "testtoken"
	do := func(method, path, tok string) *http.Response {
		req, err := http.NewRequest(method, ts.URL+path, nil)
		if err != nil {
			t.Fatal(err)
		}
		if tok != "" {
			req.Header.Set("X-Token", tok)
		}
		resp, err := http.DefaultClient.Do(req)
		if err != nil {
			t.Fatal(err)
		}
		return resp
	}
	decodeErr := func(t *testing.T, resp *http.Response) apiErr {
		t.Helper()
		defer resp.Body.Close()
		var e apiErr
		if err := json.NewDecoder(resp.Body).Decode(&e); err != nil {
			t.Fatal(err)
		}
		return e
	}

	t.Run("auth required on all /api paths", func(t *testing.T) {
		for _, p := range []string{
			"/api/devices", "/api/devices/jupiter",
			"/api/devices/jupiter/wake", "/api/devices/jupiter/off",
		} {
			resp := do(http.MethodGet, p, "")
			if resp.StatusCode != http.StatusUnauthorized {
				t.Errorf("%s without token: got %d, want 401", p, resp.StatusCode)
				resp.Body.Close()
				continue
			}
			e := decodeErr(t, resp)
			if e.OK || e.Error.Code != "unauthorized" {
				t.Errorf("%s: error body = %+v", p, e)
			}
			if ct := resp.Header.Get("Content-Type"); !strings.Contains(ct, "application/json") {
				t.Errorf("%s: content-type = %q, want application/json", p, ct)
			}
		}
	})

	t.Run("bad token rejected", func(t *testing.T) {
		resp := do(http.MethodGet, "/api/devices", "wrong")
		if resp.StatusCode != http.StatusUnauthorized {
			t.Fatalf("got %d, want 401", resp.StatusCode)
		}
		if e := decodeErr(t, resp); e.Error.Code != "unauthorized" {
			t.Errorf("error code = %q, want unauthorized", e.Error.Code)
		}
	})

	t.Run("list devices", func(t *testing.T) {
		resp := do(http.MethodGet, "/api/devices", token)
		if resp.StatusCode != http.StatusOK {
			t.Fatalf("got %d, want 200", resp.StatusCode)
		}
		defer resp.Body.Close()
		var body struct {
			OK      bool `json:"ok"`
			Devices map[string]struct {
				MAC      string `json:"mac"`
				State    string `json:"state"`
				Wake     bool   `json:"wake"`
				Poweroff bool   `json:"poweroff"`
			} `json:"devices"`
		}
		if err := json.NewDecoder(resp.Body).Decode(&body); err != nil {
			t.Fatal(err)
		}
		if !body.OK {
			t.Error("ok = false")
		}
		j := body.Devices["jupiter"]
		if j.MAC != "00:11:22:33:44:55" || j.State != "off" || !j.Wake || !j.Poweroff {
			t.Errorf("jupiter = %+v", j)
		}
		n := body.Devices["nomac"]
		if n.Wake || n.Poweroff {
			t.Errorf("nomac capabilities = %+v, want no wake/poweroff", n)
		}
	})

	t.Run("get single device", func(t *testing.T) {
		resp := do(http.MethodGet, "/api/devices/jupiter", token)
		if resp.StatusCode != http.StatusOK {
			t.Fatalf("got %d, want 200", resp.StatusCode)
		}
		defer resp.Body.Close()
		var body struct {
			OK     bool `json:"ok"`
			Device struct {
				State string `json:"state"`
				Wake  bool   `json:"wake"`
			} `json:"device"`
		}
		if err := json.NewDecoder(resp.Body).Decode(&body); err != nil {
			t.Fatal(err)
		}
		if !body.OK || body.Device.State != "off" || !body.Device.Wake {
			t.Errorf("body = %+v", body)
		}
	})

	t.Run("wake returns ok (udp to loopback)", func(t *testing.T) {
		resp := do(http.MethodPost, "/api/devices/jupiter/wake", token)
		if resp.StatusCode != http.StatusOK {
			t.Fatalf("got %d, want 200", resp.StatusCode)
		}
		var body struct {
			OK bool `json:"ok"`
		}
		if err := json.NewDecoder(resp.Body).Decode(&body); err != nil {
			t.Fatal(err)
		}
		resp.Body.Close()
		if !body.OK {
			t.Error("ok = false")
		}
	})

	t.Run("poweroff idempotent when target unreachable", func(t *testing.T) {
		resp := do(http.MethodPost, "/api/devices/jupiter/off", token)
		if resp.StatusCode != http.StatusOK {
			t.Fatalf("got %d, want 200", resp.StatusCode)
		}
		resp.Body.Close()
	})

	t.Run("unknown device is 404 not_found", func(t *testing.T) {
		resp := do(http.MethodPost, "/api/devices/venus/wake", token)
		if resp.StatusCode != http.StatusNotFound {
			t.Fatalf("got %d, want 404", resp.StatusCode)
		}
		if e := decodeErr(t, resp); e.OK || e.Error.Code != "not_found" {
			t.Errorf("error body = %+v", e)
		}
	})

	t.Run("device without mac is 400 bad_request", func(t *testing.T) {
		resp := do(http.MethodPost, "/api/devices/nomac/wake", token)
		if resp.StatusCode != http.StatusBadRequest {
			t.Fatalf("got %d, want 400", resp.StatusCode)
		}
		if e := decodeErr(t, resp); e.OK || e.Error.Code != "bad_request" {
			t.Errorf("error body = %+v", e)
		}
	})

	t.Run("root is public and renders the readme", func(t *testing.T) {
		resp := do(http.MethodGet, "/", "") // no token
		defer resp.Body.Close()
		body, err := io.ReadAll(resp.Body)
		if err != nil {
			t.Fatal(err)
		}
		if resp.StatusCode != http.StatusOK {
			t.Fatalf("got %d, want 200", resp.StatusCode)
		}
		if ct := resp.Header.Get("Content-Type"); !strings.Contains(ct, "text/html") {
			t.Errorf("content-type = %q, want text/html", ct)
		}
		s := string(body)
		if !strings.Contains(s, "<title>hassctl</title>") {
			t.Error("page is missing the title")
		}
		if !strings.Contains(s, "netbird-gw") {
			t.Error("page is missing the readme content")
		}
		if !strings.Contains(s, "/docs") {
			t.Error("page is missing the link to the ReDoc docs page")
		}
	})

	t.Run("docs page is public and loads redoc from the pinned cdn", func(t *testing.T) {
		resp := do(http.MethodGet, "/docs", "")
		defer resp.Body.Close()
		body, err := io.ReadAll(resp.Body)
		if err != nil {
			t.Fatal(err)
		}
		if resp.StatusCode != http.StatusOK {
			t.Fatalf("got %d, want 200", resp.StatusCode)
		}
		s := string(body)
		if !strings.Contains(s, "<redoc spec-url=\"/openapi.yaml\">") {
			t.Error("docs page is missing the redoc element")
		}
		if !strings.Contains(s, "https://cdn.jsdelivr.net/npm/redoc@2.5.3/bundles/redoc.standalone.js") {
			t.Error("docs page is missing the pinned cdn script tag")
		}
	})

	t.Run("openapi spec is public", func(t *testing.T) {
		resp := do(http.MethodGet, "/openapi.yaml", "")
		defer resp.Body.Close()
		body, err := io.ReadAll(resp.Body)
		if err != nil {
			t.Fatal(err)
		}
		if resp.StatusCode != http.StatusOK {
			t.Fatalf(
				"got %d, want 200", resp.StatusCode)
		}
		if !strings.HasPrefix(string(body), "openapi: 3.1.0") {
			t.Error("spec body does not start with the openapi version")
		}
	})
}

// TestUnreachableClassification covers the poweroff idempotency rule:
// connection-level dial failures (machine already off / LAN down) are
// "already off" successes, while SSH-level failures and DNS errors are
// misconfiguration and must surface as real errors.
func TestUnreachableClassification(t *testing.T) {
	_, err := net.DialTimeout("tcp", "127.0.0.1:1", time.Second)
	if err == nil {
		t.Fatal("expected dial to 127.0.0.1:1 to fail")
	}
	if !unreachable(err) {
		t.Errorf("connection refused should classify as unreachable: %v", err)
	}
	if unreachable(errors.New(
		"ssh: handshake failed: ssh: unable to authenticate, no supported methods remain")) {
		t.Error("auth failure must not classify as unreachable")
	}
	if unreachable(io.EOF) {
		t.Error("EOF during handshake must not classify as unreachable")
	}
	dnsErr := &net.OpError{Op: "dial", Err: &net.DNSError{Err: "no such host", Name: "nope.invalid"}}
	if unreachable(dnsErr) {
		t.Error("DNS failure must not classify as unreachable")
	}
}

// TestPoweroffSurfacesSSHFailures points the poweroff target at a fake
// sshd that accepts and immediately closes after a version banner. The
// client handshake then fails with a non-network error, which must come
// back to the caller as a 500 instead of the idempotent 200.
func TestPoweroffSurfacesSSHFailures(t *testing.T) {
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer ln.Close()
	go func() {
		for {
			conn, err := ln.Accept()
			if err != nil {
				return
			}
			conn.Write([]byte("SSH-2.0-notaserver\r\n"))
			// Drain the client's banner + kexinit so the close below is a
			// graceful FIN: closing with unread data would send an RST, which
			// the client would (correctly) classify as a network error instead
			// of the clean EOF we want here. Stop after a short deadline to
			// keep the test fast.
			conn.SetReadDeadline(time.Now().Add(200 * time.Millisecond))
			io.Copy(io.Discard, conn)
			conn.Close()
		}
	}()

	cfg := testConfig(t)
	cfg.Devices["jupiter"].Poweroff.Addr = ln.Addr().String()
	ts := httptest.NewServer(newServer(cfg).handler())
	defer ts.Close()

	req, err := http.NewRequest(http.MethodPost, ts.URL+"/api/devices/jupiter/off", nil)
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("X-Token", "testtoken")
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusInternalServerError {
		t.Errorf("got %d, want 500 (SSH handshake failure must surface)", resp.StatusCode)
	}
	var body struct {
		OK    bool `json:"ok"`
		Error struct {
			Code    string `json:"code"`
			Message string `json:"message"`
		} `json:"error"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&body); err != nil {
		t.Fatal(err)
	}
	if body.Error.Code != "internal" {
		t.Errorf("error code = %q, want internal", body.Error.Code)
	}
}
