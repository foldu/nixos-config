// Command ovh-dns edits the DNS zones of an OVH account using the credentials
// that are already in sops, so the OVH_* variables never have to be exported by
// hand:
//
//	ovh-dns set A fish.home.5kw.li 192.0.2.10
//	ovh-dns set CNAME frosch.5kw.li jupiter.home.5kw.li
//
// The credentials live in `caddy: env:` in secrets/secrets.yaml and are
// decrypted in-process, so neither sops nor the OVHcloud CLI has to be
// installed. Only the OVH_* entries of that file are used; the unrelated caddy
// secrets beside them are ignored.
//
// The zone is worked out from the name, and OVH only publishes an edited zone
// to its nameservers when explicitly asked, so set and rm refresh by default.
package main

import (
	"errors"
	"fmt"
	"io"
	"net"
	"os"
	"strconv"
	"strings"
	"text/tabwriter"
)

const (
	defaultSecretsFile = "secrets/secrets.yaml"
	defaultEndpoint    = "ovh-eu"
)

// requiredKeys must be present under caddy/env.
var requiredKeys = []string{
	"OVH_APPLICATION_KEY",
	"OVH_APPLICATION_SECRET",
	"OVH_CONSUMER_KEY",
}

var errHelp = errors.New("help requested")

// app holds the streams and the two things that reach outside the process, so
// tests can stand in for the secrets file and the OVH API.
type app struct {
	stdin  io.Reader
	stdout io.Writer
	stderr io.Writer

	loadCredentials func(file string) (creds, error)
	connect         func(creds) (dnsAPI, error)
}

type options struct {
	secretsFile string
	zone        string
	fieldType   string
	ttl         int64
	hasTTL      bool
	autoRefresh bool
	dryRun      bool
	positionals []string
}

func main() {
	os.Exit(newApp(os.Stdout, os.Stderr).run(os.Args[1:]))
}

func newApp(stdout, stderr io.Writer) *app {
	return &app{
		stdin:           os.Stdin,
		stdout:          stdout,
		stderr:          stderr,
		loadCredentials: loadCredentials,
		connect:         func(c creds) (dnsAPI, error) { return newClient(c) },
	}
}

// note reports progress on stderr, leaving stdout for the data itself.
func (a *app) note(format string, args ...any) {
	fmt.Fprintf(a.stderr, "ovh-dns: "+format+"\n", args...)
}

func (a *app) errorf(format string, args ...any) int {
	fmt.Fprintf(a.stderr, "ovh-dns: "+format+"\n", args...)
	return 1
}

func (a *app) run(args []string) int {
	opts, err := parseArgs(args)
	if errors.Is(err, errHelp) {
		usage(a.stdout)
		return 0
	}
	if err != nil {
		a.note("%v", err)
		return 2
	}
	if len(opts.positionals) == 0 {
		usage(a.stderr)
		return 2
	}

	command, rest := opts.positionals[0], opts.positionals[1:]
	if command == "help" {
		usage(a.stdout)
		return 0
	}

	handlers := map[string]func(dnsAPI, *options, []string) int{
		"set":     a.set,
		"rm":      a.rm,
		"list":    a.list,
		"zones":   a.zones,
		"refresh": a.refresh,
	}
	handler, known := handlers[command]
	if !known {
		return a.errorf("unknown command %q (try 'ovh-dns --help')", command)
	}

	file, err := resolveSecretsFile(opts.secretsFile)
	if err != nil {
		return a.errorf("%v", err)
	}
	credentials, err := a.loadCredentials(file)
	if err != nil {
		return a.errorf("%v", err)
	}
	api, err := a.connect(credentials)
	if err != nil {
		return a.errorf("%v", err)
	}

	return handler(api, opts, rest)
}

// parseArgs takes the wrapper's options from anywhere on the line; whatever is
// left over is the command and its arguments.
func parseArgs(args []string) (*options, error) {
	opts := &options{secretsFile: defaultSecretsFile, autoRefresh: true}
	if file := os.Getenv("OVH_DNS_SECRETS_FILE"); file != "" {
		opts.secretsFile = file
	}

	for i := 0; i < len(args); i++ {
		arg := args[i]
		name, value, attached := strings.Cut(arg, "=")

		switch name {
		case "--secrets-file", "--zone", "--ttl", "--type":
			if !attached {
				if i+1 >= len(args) {
					return nil, fmt.Errorf("%s needs a value", name)
				}
				i++
				value = args[i]
			}
			switch name {
			case "--secrets-file":
				opts.secretsFile = value
			case "--zone":
				opts.zone = normalise(value)
			case "--ttl":
				ttl, err := strconv.ParseInt(value, 10, 64)
				if err != nil || ttl < 0 {
					return nil, fmt.Errorf("--ttl wants a number of seconds, got %q", value)
				}
				opts.ttl, opts.hasTTL = ttl, true
			case "--type":
				opts.fieldType = strings.ToUpper(value)
			}
		case "--no-refresh":
			opts.autoRefresh = false
		case "-n", "--dry-run":
			opts.dryRun = true
		case "-h", "--help":
			return nil, errHelp
		default:
			if strings.HasPrefix(arg, "-") && arg != "-" {
				return nil, fmt.Errorf("unknown option %q (try 'ovh-dns --help')", arg)
			}
			opts.positionals = append(opts.positionals, arg)
		}
	}
	return opts, nil
}

// set creates a record, or rewrites the one that is already there. It is the
// command you want most of the time: it does not care whether the name exists
// yet, and it collapses duplicates of the same name and type.
func (a *app) set(api dnsAPI, opts *options, args []string) int {
	if len(args) != 3 {
		return a.errorf("usage: ovh-dns set <type> <name> <target>")
	}
	fieldType := strings.ToUpper(args[0])
	name, target := args[1], args[2]

	if err := validateTarget(fieldType, target); err != nil {
		return a.errorf("%v", err)
	}

	zone, sub, err := a.resolve(api, opts, name)
	if err != nil {
		return a.errorf("%v", err)
	}
	existing, err := api.records(zone, fieldType, sub)
	if err != nil {
		return a.errorf("%v", err)
	}

	if len(existing) == 1 && existing[0].Target == target && (!opts.hasTTL || existing[0].TTL == opts.ttl) {
		a.note("%s %s already points at %s", fieldType, name, target)
		return 0
	}

	// Keep the record's own TTL unless one was asked for.
	ttl := opts.ttl
	if !opts.hasTTL && len(existing) > 0 {
		ttl = existing[0].TTL
	}

	if opts.dryRun {
		if len(existing) == 0 {
			a.note("would create %s %s -> %s", fieldType, name, target)
			return 0
		}
		a.note("would update %s %s from %s to %s", fieldType, name, existing[0].Target, target)
		for _, extra := range existing[1:] {
			a.note("would remove duplicate id %d (%s)", extra.ID, extra.Target)
		}
		return 0
	}

	if len(existing) == 0 {
		created, err := api.create(zone, record{FieldType: fieldType, SubDomain: sub, Target: target, TTL: ttl})
		if err != nil {
			return a.errorf("%v", err)
		}
		a.note("created %s %s -> %s (id %d)", fieldType, name, target, created.ID)
	} else {
		if err := api.update(zone, existing[0].ID, target, ttl); err != nil {
			return a.errorf("%v", err)
		}
		a.note("updated %s %s -> %s (id %d)", fieldType, name, target, existing[0].ID)
		for _, extra := range existing[1:] {
			if err := api.remove(zone, extra.ID); err != nil {
				return a.errorf("%v", err)
			}
			a.note("removed duplicate id %d (%s)", extra.ID, extra.Target)
		}
	}

	return a.publish(api, opts, zone)
}

// rm deletes the records of one name and type, or just the one pointing at a
// given target.
func (a *app) rm(api dnsAPI, opts *options, args []string) int {
	if len(args) < 2 || len(args) > 3 {
		return a.errorf("usage: ovh-dns rm <type> <name> [target]")
	}
	fieldType := strings.ToUpper(args[0])
	name := args[1]
	want := ""
	if len(args) == 3 {
		want = args[2]
	}

	zone, sub, err := a.resolve(api, opts, name)
	if err != nil {
		return a.errorf("%v", err)
	}
	existing, err := api.records(zone, fieldType, sub)
	if err != nil {
		return a.errorf("%v", err)
	}

	var doomed []record
	for _, r := range existing {
		if want == "" || r.Target == want {
			doomed = append(doomed, r)
		}
	}
	if len(doomed) == 0 {
		a.note("nothing to remove for %s %s in %s", fieldType, name, zone)
		return 0
	}

	for _, r := range doomed {
		if opts.dryRun {
			a.note("would remove %s %s -> %s (id %d)", fieldType, name, r.Target, r.ID)
			continue
		}
		if err := api.remove(zone, r.ID); err != nil {
			return a.errorf("%v", err)
		}
		a.note("removed %s %s -> %s (id %d)", fieldType, name, r.Target, r.ID)
	}

	if opts.dryRun {
		return 0
	}
	return a.publish(api, opts, zone)
}

func (a *app) list(api dnsAPI, opts *options, args []string) int {
	if len(args) != 1 {
		return a.errorf("usage: ovh-dns list <zone|name> [--type TYPE]")
	}
	zone, sub, err := a.resolve(api, opts, args[0])
	if err != nil {
		return a.errorf("%v", err)
	}
	records, err := api.records(zone, opts.fieldType, sub)
	if err != nil {
		return a.errorf("%v", err)
	}
	if len(records) == 0 {
		a.note("no records found in %s", zone)
		return 0
	}

	table := tabwriter.NewWriter(a.stdout, 0, 0, 2, ' ', 0)
	for _, r := range records {
		name := r.SubDomain
		if name == "" {
			name = "@"
		}
		fmt.Fprintf(table, "%s\t%s\t%d\t%s\n", name, r.FieldType, r.TTL, r.Target)
	}
	table.Flush()
	return 0
}

func (a *app) zones(api dnsAPI, _ *options, args []string) int {
	if len(args) > 0 {
		return a.errorf("zones takes no arguments")
	}
	zones, err := api.zones()
	if err != nil {
		return a.errorf("%v", err)
	}
	for _, zone := range zones {
		fmt.Fprintln(a.stdout, zone)
	}
	return 0
}

func (a *app) refresh(api dnsAPI, opts *options, args []string) int {
	if len(args) != 1 {
		return a.errorf("usage: ovh-dns refresh <zone|name>")
	}
	zone, _, err := a.resolve(api, opts, args[0])
	if err != nil {
		return a.errorf("%v", err)
	}
	if opts.dryRun {
		a.note("would refresh %s", zone)
		return 0
	}
	a.note("refreshing %s", zone)
	if err := api.refresh(zone); err != nil {
		return a.errorf("%v", err)
	}
	return 0
}

// publish pushes an edited zone to the nameservers. OVH keeps the change on its
// own servers until this happens, so a zone edit on its own looks like a no-op.
func (a *app) publish(api dnsAPI, opts *options, zone string) int {
	if !opts.autoRefresh {
		a.note("not refreshing %s (--no-refresh): run 'ovh-dns refresh %s' to publish it", zone, zone)
		return 0
	}
	a.note("refreshing %s", zone)
	if err := api.refresh(zone); err != nil {
		return a.errorf("%v", err)
	}
	return 0
}

// resolve turns a name into the zone OVH is authoritative for and the subdomain
// inside it. --zone skips the lookup, which is also the way out when the
// consumer key is scoped to a single zone.
func (a *app) resolve(api dnsAPI, opts *options, name string) (zone, sub string, err error) {
	if opts.zone != "" {
		sub, err := splitName(opts.zone, name)
		if err != nil {
			return "", "", err
		}
		return opts.zone, sub, nil
	}
	return api.zoneFor(name)
}

// validateTarget catches the obvious typos before they reach a zone.
func validateTarget(fieldType, target string) error {
	ip := net.ParseIP(target)
	switch fieldType {
	case "A":
		if ip == nil || ip.To4() == nil {
			return fmt.Errorf("%q is not an IPv4 address", target)
		}
	case "AAAA":
		if ip == nil || ip.To4() != nil {
			return fmt.Errorf("%q is not an IPv6 address", target)
		}
	case "CNAME":
		if target == "" || strings.ContainsAny(target, " \t") {
			return fmt.Errorf("%q is not a hostname", target)
		}
	}
	return nil
}

func usage(w io.Writer) {
	fmt.Fprint(w, `Usage: ovh-dns <command> [options]

Manages the DNS zones of the OVH account whose credentials sit in caddy/env in
secrets/secrets.yaml. The zone is worked out from the name you give, and since
OVH only publishes an edited zone to its nameservers when asked, set and rm
refresh by default.

Commands:
  set <type> <name> <target>   Create or replace records, then publish the zone
  rm <type> <name> [target]    Delete matching records, then publish the zone
  list <zone|name>             List records
  zones                        List the zones on the account
  refresh <zone|name>          Publish a zone to the nameservers

Options:
      --zone ZONE           Zone the name belongs to, skipping the lookup
      --ttl N               TTL in seconds for set (default: the zone's own)
      --type T              Only list records of this type
      --secrets-file PATH   Read PATH instead of secrets/secrets.yaml
      --no-refresh          Do not publish the zone after a change
  -n, --dry-run             Report what would change, change nothing
  -h, --help                This text

Consumer key scope:
  Create the credentials at https://eu.api.ovh.com/createToken/ with these
  rights. They are the ones caddy-dns/ovh asks for, so a key that already
  renews certificates through the ACME challenge is enough:

    GET    /domain/zone/*/record
    POST   /domain/zone/*/record
    GET    /domain/zone/*/record/*
    PUT    /domain/zone/*/record/*
    DELETE /domain/zone/*/record/*
    POST   /domain/zone/*/refresh

  For a single zone, use the same rights with the zone name in place of *.
  'zones' additionally needs GET /domain/zone, which that set deliberately
  leaves out; name the zone with --zone instead of widening the key.

Examples:
  ovh-dns set A fish.home.5kw.li 192.0.2.10
  ovh-dns set CNAME frosch.5kw.li jupiter.home.5kw.li
  ovh-dns set TXT _acme-challenge.5kw.li "challenge-token" --ttl 60
  ovh-dns list home.5kw.li --type A
  ovh-dns rm A fish.home.5kw.li
  ovh-dns refresh 5kw.li

Environment:
  OVH_DNS_SECRETS_FILE   Secrets file to read (default secrets/secrets.yaml)
  SOPS_AGE_KEY_FILE      Age key sops should decrypt with
  OVH_ENDPOINT           API endpoint if caddy/env does not name one (default ovh-eu)

Progress goes to stderr, so 'ovh-dns list' can be piped.
`)
}
