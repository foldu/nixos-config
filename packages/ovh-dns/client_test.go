package main

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"strings"
	"sync"
	"testing"
)

// roundTripFunc answers requests in-process, so these tests exercise the real
// client and its real route strings without a socket: the Nix build sandbox has
// no network, loopback included.
type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(r *http.Request) (*http.Response, error) { return f(r) }

func jsonResponse(req *http.Request, status int, body string) *http.Response {
	return &http.Response{
		StatusCode: status,
		Status:     fmt.Sprintf("%d %s", status, http.StatusText(status)),
		Header:     http.Header{"Content-Type": []string{"application/json"}},
		Body:       io.NopCloser(strings.NewReader(body)),
		Request:    req,
	}
}

// caddyKeyTransport behaves like a consumer key made for caddy's ACME
// challenge: the record routes and the refresh work, GET /domain/zone is
// refused. It records every call so a test can assert what was asked for.
type caddyKeyTransport struct {
	mu      sync.Mutex
	calls   []string
	created string
	// zones is the set of zones this account has.
	zones []string
}

func (f *caddyKeyTransport) RoundTrip(r *http.Request) (*http.Response, error) {
	path := r.URL.Path

	f.mu.Lock()
	f.calls = append(f.calls, routeOf(r))
	f.mu.Unlock()

	switch {
	case strings.HasSuffix(path, "/auth/time"):
		return jsonResponse(r, 200, "1700000000"), nil

	case strings.HasSuffix(path, "/domain/zone"):
		return jsonResponse(r, 403, `{"class":"Client::Forbidden","message":"This call has not been granted"}`), nil

	case r.Method == http.MethodGet && strings.HasSuffix(path, "/record"):
		// Zone probes land here: an unknown zone answers 404, a known one answers
		// with the (possibly empty) list of matching record ids.
		for _, zone := range f.zones {
			if strings.HasSuffix(path, "/domain/zone/"+zone+"/record") {
				return jsonResponse(r, 200, "[]"), nil
			}
		}
		return jsonResponse(r, 404, `{"class":"Client::NotFound","message":"The requested object does not exist"}`), nil

	case r.Method == http.MethodPost && strings.HasSuffix(path, "/record"):
		body, _ := io.ReadAll(r.Body)
		f.mu.Lock()
		f.created = string(body)
		f.mu.Unlock()
		return jsonResponse(r, 200, `{"id":42,"fieldType":"A","subDomain":"fish","target":"192.0.2.10","ttl":3600}`), nil

	case r.Method == http.MethodPost && strings.HasSuffix(path, "/refresh"):
		return jsonResponse(r, 200, "null"), nil
	}

	return jsonResponse(r, 500, fmt.Sprintf(`{"message":"unexpected route %s %s"}`, r.Method, path)), nil
}

// newRealClient builds the real client, talking to the fake endpoint.
func newRealClient(t *testing.T, transport http.RoundTripper) *client {
	t.Helper()
	api, err := newClient(creds{endpoint: "ovh-eu", applicationKey: "k", applicationSecret: "s", consumerKey: "c"})
	if err != nil {
		t.Fatalf("newClient: %v", err)
	}
	api.api.Client.Transport = transport
	return api
}

// TestSetWorksWithACaddyScopedKey is the regression test for the 403 that made
// every command fail: resolution used to start with GET /domain/zone, which a
// caddy-scoped consumer key is not granted.
func TestSetWorksWithACaddyScopedKey(t *testing.T) {
	inRepo(t)
	transport := &caddyKeyTransport{zones: []string{"5kw.li", "home.5kw.li"}}
	api := newRealClient(t, transport)

	var out, errOut bytes.Buffer
	a := &app{
		stdin:  strings.NewReader(""),
		stdout: &out,
		stderr: &errOut,
		loadCredentials: func(string) (creds, error) {
			return creds{endpoint: "ovh-eu"}, nil
		},
		connect: func(creds) (dnsAPI, error) { return api, nil },
	}

	if code := a.run([]string{"set", "A", "fish.home.5kw.li", "192.0.2.10"}); code != 0 {
		t.Fatalf("exit code = %d, stderr: %s", code, errOut.String())
	}

	for _, call := range transport.calls {
		if strings.HasSuffix(call, "/domain/zone") {
			t.Errorf("the account's zone list was requested: %s", call)
		}
	}

	// It has to have worked out that home.5kw.li, not fish.home.5kw.li, is the
	// zone that holds the name, and then written fish there.
	if !strings.Contains(transport.created, `"subDomain":"fish"`) {
		t.Errorf("created %s, want subDomain fish", transport.created)
	}
	if !strings.Contains(transport.created, `"target":"192.0.2.10"`) {
		t.Errorf("created %s, want the new target", transport.created)
	}

	for _, want := range []string{
		"GET /domain/zone/fish.home.5kw.li/record",           // candidate probe, not a zone
		"GET /domain/zone/home.5kw.li/record?subDomain=fish", // candidate probe, is a zone
		"GET /domain/zone/home.5kw.li/record?fieldType=A&subDomain=fish",
		"POST /domain/zone/home.5kw.li/record",
		"POST /domain/zone/home.5kw.li/refresh",
	} {
		if !containsCall(transport.calls, want) {
			t.Errorf("missing call %q in %v", want, transport.calls)
		}
	}
}

// TestZonesExplainsTheMissingRight checks that the one command which genuinely
// needs GET /domain/zone says so instead of leaking a bare 403.
func TestZonesExplainsTheMissingRight(t *testing.T) {
	inRepo(t)
	api := newRealClient(t, &caddyKeyTransport{zones: []string{"5kw.li"}})

	var out, errOut bytes.Buffer
	a := &app{
		stdin:           strings.NewReader(""),
		stdout:          &out,
		stderr:          &errOut,
		loadCredentials: func(string) (creds, error) { return creds{endpoint: "ovh-eu"}, nil },
		connect:         func(creds) (dnsAPI, error) { return api, nil },
	}

	if code := a.run([]string{"zones"}); code != 1 {
		t.Fatalf("exit code = %d, want 1", code)
	}
	got := errOut.String()
	if !strings.Contains(got, "GET /domain/zone") || !strings.Contains(got, "--zone") {
		t.Errorf("stderr = %s, want it to name the missing right and --zone", got)
	}
}

func containsCall(calls []string, want string) bool {
	for _, call := range calls {
		if call == want {
			return true
		}
	}
	return false
}

// refuseAllTransport answers 403 to everything, the way a key that was never
// scoped for the record routes does.
type refuseAllTransport struct{}

func (refuseAllTransport) RoundTrip(r *http.Request) (*http.Response, error) {
	if strings.HasSuffix(r.URL.Path, "/auth/time") {
		return jsonResponse(r, 200, "1700000000"), nil
	}
	return jsonResponse(r, 403, `{"class":"Client::Forbidden","message":"This call has not been granted"}`), nil
}

// TestRefusedKeySaysSoNotNoSuchZone keeps the two failure modes apart: a key
// that is refused everywhere should not be reported as a missing zone.
func TestRefusedKeySaysSoNotNoSuchZone(t *testing.T) {
	inRepo(t)
	api := newRealClient(t, refuseAllTransport{})

	var out, errOut bytes.Buffer
	a := &app{
		stdin:           strings.NewReader(""),
		stdout:          &out,
		stderr:          &errOut,
		loadCredentials: func(string) (creds, error) { return creds{endpoint: "ovh-eu"}, nil },
		connect:         func(creds) (dnsAPI, error) { return api, nil },
	}

	if code := a.run([]string{"set", "A", "fish.home.5kw.li", "192.0.2.10"}); code != 1 {
		t.Fatalf("exit code = %d, want 1", code)
	}
	got := errOut.String()
	if !strings.Contains(got, "refused every zone") {
		t.Errorf("stderr = %s, want it to blame the key rather than a missing zone", got)
	}
	if strings.Contains(got, "no OVH zone found") {
		t.Errorf("stderr = %s, wrongly reported as a missing zone", got)
	}
}

// apiVersionPrefix is the part of the URL that go-ovh's endpoint config adds, so
// that recorded calls read as the API routes they are.
const apiVersionPrefix = "/1.0"

func routeOf(r *http.Request) string {
	route := r.Method + " " + strings.TrimPrefix(r.URL.Path, apiVersionPrefix)
	if r.URL.RawQuery != "" {
		route += "?" + r.URL.RawQuery
	}
	return route
}
