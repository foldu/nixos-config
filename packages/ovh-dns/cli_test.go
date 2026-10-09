package main

import (
	"bytes"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// inRepo makes the working directory look like a checkout with a secrets file.
func inRepo(t *testing.T) string {
	t.Helper()
	t.Setenv("OVH_DNS_SECRETS_FILE", "")
	t.Setenv("OVH_ENDPOINT", "")
	dir := t.TempDir()
	path := filepath.Join(dir, "secrets", "secrets.yaml")
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte("caddy:\n    env: ENC[not-really-encrypted]\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	t.Chdir(dir)
	return path
}

// fakeAPI stands in for the OVH API and records what was asked of it.
type fakeAPI struct {
	zoneList   []string
	recordList []record

	created   []record
	updated   []record
	removed   []int64
	refreshed []string

	err error
}

func (f *fakeAPI) zones() ([]string, error) {
	if f.err != nil {
		return nil, f.err
	}
	return f.zoneList, nil
}

func (f *fakeAPI) records(_, fieldType, sub string) ([]record, error) {
	if f.err != nil {
		return nil, f.err
	}
	var out []record
	for _, r := range f.recordList {
		if r.SubDomain != sub {
			continue
		}
		if fieldType != "" && !strings.EqualFold(r.FieldType, fieldType) {
			continue
		}
		out = append(out, r)
	}
	return out, nil
}

func (f *fakeAPI) create(_ string, r record) (record, error) {
	if f.err != nil {
		return record{}, f.err
	}
	r.ID = int64(100 + len(f.created))
	f.created = append(f.created, r)
	f.recordList = append(f.recordList, r)
	return r, nil
}

func (f *fakeAPI) update(_ string, id int64, target string, ttl int64) error {
	if f.err != nil {
		return f.err
	}
	f.updated = append(f.updated, record{ID: id, Target: target, TTL: ttl})
	return nil
}

func (f *fakeAPI) remove(_ string, id int64) error {
	if f.err != nil {
		return f.err
	}
	f.removed = append(f.removed, id)
	return nil
}

func (f *fakeAPI) refresh(zone string) error {
	if f.err != nil {
		return f.err
	}
	f.refreshed = append(f.refreshed, zone)
	return nil
}

type harness struct {
	app    *app
	stdout *bytes.Buffer
	stderr *bytes.Buffer
	api    *fakeAPI
}

func newHarness(t *testing.T, api *fakeAPI) *harness {
	t.Helper()
	inRepo(t)
	h := &harness{stdout: &bytes.Buffer{}, stderr: &bytes.Buffer{}, api: api}
	h.app = &app{
		stdin:  strings.NewReader(""),
		stdout: h.stdout,
		stderr: h.stderr,
		loadCredentials: func(string) (creds, error) {
			return creds{endpoint: "ovh-eu", applicationKey: "k", applicationSecret: "s", consumerKey: "c"}, nil
		},
		connect: func(creds) (dnsAPI, error) { return api, nil },
	}
	return h
}

// homeZones mirrors the real account: 5kw.li with home.5kw.li delegated out of
// it, so name resolution has something to get wrong.
func homeZones() *fakeAPI {
	return &fakeAPI{zoneList: []string{"5kw.li", "home.5kw.li"}}
}

func TestParseArgs(t *testing.T) {
	t.Setenv("OVH_DNS_SECRETS_FILE", "")

	opts, err := parseArgs([]string{"set", "A", "fish.home.5kw.li", "192.0.2.10"})
	if err != nil {
		t.Fatalf("parseArgs: %v", err)
	}
	if opts.secretsFile != defaultSecretsFile || !opts.autoRefresh || opts.dryRun || opts.hasTTL {
		t.Errorf("unexpected defaults: %+v", opts)
	}
	want := []string{"set", "A", "fish.home.5kw.li", "192.0.2.10"}
	if strings.Join(opts.positionals, " ") != strings.Join(want, " ") {
		t.Errorf("positionals = %q, want %q", opts.positionals, want)
	}

	opts, err = parseArgs([]string{"--ttl", "60", "-n", "--no-refresh", "--secrets-file", "x.yaml", "set", "A", "n", "t"})
	if err != nil {
		t.Fatalf("parseArgs: %v", err)
	}
	if opts.ttl != 60 || !opts.hasTTL || !opts.dryRun || opts.autoRefresh || opts.secretsFile != "x.yaml" {
		t.Errorf("flags ignored: %+v", opts)
	}

	opts, err = parseArgs([]string{"--ttl=300", "--type=a", "list", "5kw.li"})
	if err != nil {
		t.Fatalf("parseArgs: %v", err)
	}
	if opts.ttl != 300 || !opts.hasTTL || opts.fieldType != "A" {
		t.Errorf("--flag=value not understood: %+v", opts)
	}

	// A TXT target can contain an "=" and must survive as a positional.
	opts, err = parseArgs([]string{"set", "TXT", "5kw.li", "v=spf1 -all"})
	if err != nil {
		t.Fatalf("parseArgs: %v", err)
	}
	if opts.positionals[3] != "v=spf1 -all" {
		t.Errorf("target mangled: %q", opts.positionals[3])
	}

	if _, err := parseArgs([]string{"--ttl"}); err == nil {
		t.Error("--ttl without a value should fail")
	}
	if _, err := parseArgs([]string{"--ttl", "soon"}); err == nil {
		t.Error("a non-numeric --ttl should fail")
	}
	if _, err := parseArgs([]string{"--nope"}); err == nil {
		t.Error("an unknown option should fail")
	}
	if _, err := parseArgs([]string{"-h"}); !errors.Is(err, errHelp) {
		t.Errorf("-h should report help, got %v", err)
	}

	t.Setenv("OVH_DNS_SECRETS_FILE", "from-env.yaml")
	opts, err = parseArgs([]string{"zones"})
	if err != nil {
		t.Fatalf("parseArgs: %v", err)
	}
	if opts.secretsFile != "from-env.yaml" {
		t.Errorf("environment default ignored: %+v", opts)
	}
}

func TestSetCreatesInTheDelegatedZone(t *testing.T) {
	api := homeZones()
	h := newHarness(t, api)

	if code := h.app.run([]string{"set", "A", "fish.home.5kw.li", "192.0.2.10"}); code != 0 {
		t.Fatalf("exit code = %d, stderr: %s", code, h.stderr)
	}
	if len(api.created) != 1 {
		t.Fatalf("created = %v, want one record", api.created)
	}
	got := api.created[0]
	if got.FieldType != "A" || got.SubDomain != "fish" || got.Target != "192.0.2.10" {
		t.Errorf("created %+v", got)
	}
	if len(api.updated) != 0 {
		t.Errorf("unexpected updates: %v", api.updated)
	}
	if len(api.refreshed) != 1 || api.refreshed[0] != "home.5kw.li" {
		t.Errorf("refreshed = %v, want [home.5kw.li]", api.refreshed)
	}
}

func TestSetUppercasesTheType(t *testing.T) {
	api := homeZones()
	h := newHarness(t, api)

	if code := h.app.run([]string{"set", "cname", "frosch.5kw.li", "jupiter.home.5kw.li"}); code != 0 {
		t.Fatalf("exit code = %d, stderr: %s", code, h.stderr)
	}
	if len(api.created) != 1 || api.created[0].FieldType != "CNAME" {
		t.Fatalf("created = %v", api.created)
	}
	if api.created[0].SubDomain != "frosch" {
		t.Errorf("subDomain = %q, want frosch", api.created[0].SubDomain)
	}
}

func TestSetApexRecord(t *testing.T) {
	api := homeZones()
	h := newHarness(t, api)

	if code := h.app.run([]string{"set", "A", "5kw.li", "192.0.2.1"}); code != 0 {
		t.Fatalf("exit code = %d, stderr: %s", code, h.stderr)
	}
	if len(api.created) != 1 || api.created[0].SubDomain != "" {
		t.Fatalf("apex record = %v, want an empty subDomain", api.created)
	}
}

func TestSetUpdatesInPlace(t *testing.T) {
	api := homeZones()
	api.recordList = []record{{ID: 7, FieldType: "A", SubDomain: "fish", Target: "192.0.2.9", TTL: 300}}
	h := newHarness(t, api)

	if code := h.app.run([]string{"set", "A", "fish.home.5kw.li", "192.0.2.10"}); code != 0 {
		t.Fatalf("exit code = %d, stderr: %s", code, h.stderr)
	}
	if len(api.created) != 0 {
		t.Errorf("a record already existed, but one was created: %v", api.created)
	}
	if len(api.updated) != 1 || api.updated[0].ID != 7 || api.updated[0].Target != "192.0.2.10" {
		t.Fatalf("updated = %v, want id 7 -> 192.0.2.10", api.updated)
	}
	if api.updated[0].TTL != 300 {
		t.Errorf("ttl = %d, want the record's own 300 to be kept", api.updated[0].TTL)
	}
	if len(api.refreshed) != 1 {
		t.Errorf("refreshed = %v, want one refresh", api.refreshed)
	}
}

func TestSetHonoursTTL(t *testing.T) {
	api := homeZones()
	api.recordList = []record{{ID: 7, FieldType: "A", SubDomain: "fish", Target: "192.0.2.9", TTL: 300}}
	h := newHarness(t, api)

	if code := h.app.run([]string{"set", "A", "fish.home.5kw.li", "192.0.2.10", "--ttl", "60"}); code != 0 {
		t.Fatalf("exit code = %d, stderr: %s", code, h.stderr)
	}
	if len(api.updated) != 1 || api.updated[0].TTL != 60 {
		t.Errorf("updated = %v, want ttl 60", api.updated)
	}
}

func TestSetIsIdempotent(t *testing.T) {
	api := homeZones()
	api.recordList = []record{{ID: 7, FieldType: "A", SubDomain: "fish", Target: "192.0.2.10", TTL: 300}}
	h := newHarness(t, api)

	if code := h.app.run([]string{"set", "A", "fish.home.5kw.li", "192.0.2.10"}); code != 0 {
		t.Fatalf("exit code = %d, stderr: %s", code, h.stderr)
	}
	if len(api.created) != 0 || len(api.updated) != 0 || len(api.removed) != 0 {
		t.Errorf("nothing changed, but the API was changed: %+v", api)
	}
	if len(api.refreshed) != 0 {
		t.Errorf("nothing changed, but the zone was refreshed: %v", api.refreshed)
	}
	if !strings.Contains(h.stderr.String(), "already points at") {
		t.Errorf("stderr = %s", h.stderr)
	}
}

func TestSetCollapsesDuplicates(t *testing.T) {
	api := homeZones()
	api.recordList = []record{
		{ID: 7, FieldType: "A", SubDomain: "fish", Target: "192.0.2.9", TTL: 300},
		{ID: 8, FieldType: "A", SubDomain: "fish", Target: "192.0.2.8", TTL: 300},
	}
	h := newHarness(t, api)

	if code := h.app.run([]string{"set", "A", "fish.home.5kw.li", "192.0.2.10"}); code != 0 {
		t.Fatalf("exit code = %d, stderr: %s", code, h.stderr)
	}
	if len(api.updated) != 1 || api.updated[0].ID != 7 {
		t.Errorf("updated = %v, want the first record to be reused", api.updated)
	}
	if len(api.removed) != 1 || api.removed[0] != 8 {
		t.Errorf("removed = %v, want the duplicate id 8 dropped", api.removed)
	}
}

func TestSetDryRunChangesNothing(t *testing.T) {
	api := homeZones()
	h := newHarness(t, api)

	if code := h.app.run([]string{"--dry-run", "set", "A", "fish.home.5kw.li", "192.0.2.10"}); code != 0 {
		t.Fatalf("exit code = %d, stderr: %s", code, h.stderr)
	}
	if len(api.created) != 0 || len(api.updated) != 0 || len(api.removed) != 0 || len(api.refreshed) != 0 {
		t.Errorf("dry run touched the API: %+v", api)
	}
	if !strings.Contains(h.stderr.String(), "would create A fish.home.5kw.li -> 192.0.2.10") {
		t.Errorf("stderr = %s", h.stderr)
	}
}

func TestSetNoRefresh(t *testing.T) {
	api := homeZones()
	h := newHarness(t, api)

	if code := h.app.run([]string{"--no-refresh", "set", "A", "fish.home.5kw.li", "192.0.2.10"}); code != 0 {
		t.Fatalf("exit code = %d, stderr: %s", code, h.stderr)
	}
	if len(api.created) != 1 {
		t.Fatalf("created = %v", api.created)
	}
	if len(api.refreshed) != 0 {
		t.Errorf("--no-refresh still refreshed: %v", api.refreshed)
	}
}

func TestSetRejectsBadAddress(t *testing.T) {
	api := homeZones()
	h := newHarness(t, api)

	if code := h.app.run([]string{"set", "A", "fish.home.5kw.li", "192.1432.4.5"}); code != 1 {
		t.Errorf("exit code = %d, want 1", code)
	}
	if len(api.created) != 0 {
		t.Errorf("an invalid address was still sent: %v", api.created)
	}
	if !strings.Contains(h.stderr.String(), "is not an IPv4 address") {
		t.Errorf("stderr = %s", h.stderr)
	}
}

func TestSetWrongArgumentCount(t *testing.T) {
	h := newHarness(t, homeZones())

	if code := h.app.run([]string{"set", "A", "fish.home.5kw.li"}); code != 1 {
		t.Errorf("exit code = %d, want 1", code)
	}
	if !strings.Contains(h.stderr.String(), "usage: ovh-dns set") {
		t.Errorf("stderr = %s", h.stderr)
	}
}

func TestSetUnknownZone(t *testing.T) {
	h := newHarness(t, homeZones())

	if code := h.app.run([]string{"set", "A", "fish.elsewhere.net", "192.0.2.10"}); code != 1 {
		t.Errorf("exit code = %d, want 1", code)
	}
	if !strings.Contains(h.stderr.String(), "not in any zone") {
		t.Errorf("stderr = %s", h.stderr)
	}
}

func TestRmRemovesMatchingRecords(t *testing.T) {
	api := homeZones()
	api.recordList = []record{
		{ID: 7, FieldType: "A", SubDomain: "fish", Target: "192.0.2.9", TTL: 300},
		{ID: 8, FieldType: "TXT", SubDomain: "fish", Target: "hello", TTL: 300},
	}
	h := newHarness(t, api)

	if code := h.app.run([]string{"rm", "A", "fish.home.5kw.li"}); code != 0 {
		t.Fatalf("exit code = %d, stderr: %s", code, h.stderr)
	}
	if len(api.removed) != 1 || api.removed[0] != 7 {
		t.Errorf("removed = %v, want only the A record", api.removed)
	}
	if len(api.refreshed) != 1 {
		t.Errorf("refreshed = %v, want one refresh", api.refreshed)
	}
}

func TestRmByTarget(t *testing.T) {
	api := homeZones()
	api.recordList = []record{
		{ID: 7, FieldType: "A", SubDomain: "fish", Target: "192.0.2.9", TTL: 300},
		{ID: 8, FieldType: "A", SubDomain: "fish", Target: "192.0.2.8", TTL: 300},
	}
	h := newHarness(t, api)

	if code := h.app.run([]string{"rm", "A", "fish.home.5kw.li", "192.0.2.8"}); code != 0 {
		t.Fatalf("exit code = %d, stderr: %s", code, h.stderr)
	}
	if len(api.removed) != 1 || api.removed[0] != 8 {
		t.Errorf("removed = %v, want only id 8", api.removed)
	}
}

func TestRmNothingToDo(t *testing.T) {
	api := homeZones()
	h := newHarness(t, api)

	if code := h.app.run([]string{"rm", "A", "fish.home.5kw.li"}); code != 0 {
		t.Fatalf("exit code = %d, stderr: %s", code, h.stderr)
	}
	if len(api.removed) != 0 || len(api.refreshed) != 0 {
		t.Errorf("nothing matched, but the API was touched: %+v", api)
	}
}

func TestRmDryRun(t *testing.T) {
	api := homeZones()
	api.recordList = []record{{ID: 7, FieldType: "A", SubDomain: "fish", Target: "192.0.2.9", TTL: 300}}
	h := newHarness(t, api)

	if code := h.app.run([]string{"--dry-run", "rm", "A", "fish.home.5kw.li"}); code != 0 {
		t.Fatalf("exit code = %d, stderr: %s", code, h.stderr)
	}
	if len(api.removed) != 0 || len(api.refreshed) != 0 {
		t.Errorf("dry run removed something: %+v", api)
	}
	if !strings.Contains(h.stderr.String(), "would remove A fish.home.5kw.li -> 192.0.2.9") {
		t.Errorf("stderr = %s", h.stderr)
	}
}

func TestListPrintsRecords(t *testing.T) {
	api := homeZones()
	api.recordList = []record{
		{ID: 7, FieldType: "A", SubDomain: "fish", Target: "192.0.2.9", TTL: 300},
		{ID: 8, FieldType: "TXT", SubDomain: "fish", Target: "hello", TTL: 300},
		{ID: 9, FieldType: "A", SubDomain: "", Target: "192.0.2.1", TTL: 3600},
	}

	h := newHarness(t, api)
	if code := h.app.run([]string{"list", "5kw.li"}); code != 0 {
		t.Fatalf("exit code = %d, stderr: %s", code, h.stderr)
	}
	out := h.stdout.String()
	if !strings.Contains(out, "@") || !strings.Contains(out, "192.0.2.1") {
		t.Errorf("the apex record is missing from:\n%s", out)
	}

	// Narrowed to one name.
	h = newHarness(t, api)
	if code := h.app.run([]string{"list", "fish.home.5kw.li"}); code != 0 {
		t.Fatalf("exit code = %d", code)
	}
	out = h.stdout.String()
	if strings.Contains(out, "192.0.2.1") {
		t.Errorf("a name listing leaked the apex record:\n%s", out)
	}
	if !strings.Contains(out, "192.0.2.9") || !strings.Contains(out, "hello") {
		t.Errorf("missing records:\n%s", out)
	}

	// And narrowed to one type.
	h = newHarness(t, api)
	if code := h.app.run([]string{"list", "5kw.li", "--type", "A"}); code != 0 {
		t.Fatalf("exit code = %d", code)
	}
	out = h.stdout.String()
	if strings.Contains(out, "hello") {
		t.Errorf("--type A still listed the TXT record:\n%s", out)
	}
}

func TestZones(t *testing.T) {
	h := newHarness(t, homeZones())

	if code := h.app.run([]string{"zones"}); code != 0 {
		t.Fatalf("exit code = %d, stderr: %s", code, h.stderr)
	}
	if got := h.stdout.String(); got != "5kw.li\nhome.5kw.li\n" {
		t.Errorf("zones output = %q", got)
	}
}

func TestRefresh(t *testing.T) {
	api := homeZones()
	h := newHarness(t, api)

	if code := h.app.run([]string{"refresh", "fish.home.5kw.li"}); code != 0 {
		t.Fatalf("exit code = %d, stderr: %s", code, h.stderr)
	}
	if len(api.refreshed) != 1 || api.refreshed[0] != "home.5kw.li" {
		t.Errorf("refreshed = %v, want [home.5kw.li]", api.refreshed)
	}
}

func TestAPIErrorIsReported(t *testing.T) {
	api := homeZones()
	api.err = errors.New("OVH API 500: something went wrong")
	h := newHarness(t, api)

	if code := h.app.run([]string{"zones"}); code != 1 {
		t.Errorf("exit code = %d, want 1", code)
	}
	if !strings.Contains(h.stderr.String(), "something went wrong") {
		t.Errorf("stderr = %s", h.stderr)
	}
}

func TestCredentialFailureStopsTheRun(t *testing.T) {
	api := homeZones()
	h := newHarness(t, api)
	h.app.loadCredentials = func(string) (creds, error) {
		return creds{}, errors.New("no OVH_APPLICATION_KEY under caddy/env")
	}

	if code := h.app.run([]string{"zones"}); code != 1 {
		t.Errorf("exit code = %d, want 1", code)
	}
	if !strings.Contains(h.stderr.String(), "OVH_APPLICATION_KEY") {
		t.Errorf("stderr = %s", h.stderr)
	}
}

func TestUnknownCommandNeedsNoCredentials(t *testing.T) {
	h := newHarness(t, homeZones())

	if code := h.app.run([]string{"frobnicate"}); code != 1 {
		t.Errorf("exit code = %d, want 1", code)
	}
	if !strings.Contains(h.stderr.String(), "unknown command") {
		t.Errorf("stderr = %s", h.stderr)
	}
}

func TestNoArguments(t *testing.T) {
	h := newHarness(t, homeZones())

	if code := h.app.run(nil); code != 2 {
		t.Errorf("exit code = %d, want 2", code)
	}
	if !strings.Contains(h.stderr.String(), "Usage: ovh-dns") {
		t.Errorf("usage should go to stderr: %s", h.stderr)
	}
}

func TestHelp(t *testing.T) {
	for _, arg := range []string{"--help", "-h", "help"} {
		h := newHarness(t, homeZones())
		if code := h.app.run([]string{arg}); code != 0 {
			t.Errorf("%s: exit code = %d, want 0", arg, code)
		}
		if !strings.Contains(h.stdout.String(), "Usage: ovh-dns") {
			t.Errorf("%s: usage should go to stdout: %s", arg, h.stdout)
		}
	}
}
