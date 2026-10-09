package main

import (
	"errors"
	"fmt"
	"net/url"
	"sort"
	"strings"

	"github.com/ovh/go-ovh/ovh"
)

// record is a DNS record the way the OVH API represents it.
type record struct {
	ID        int64  `json:"id"`
	FieldType string `json:"fieldType"`
	SubDomain string `json:"subDomain"`
	Target    string `json:"target"`
	TTL       int64  `json:"ttl"`
}

// dnsAPI is the slice of the OVH API the commands need. Tests stand in for it.
type dnsAPI interface {
	zones() ([]string, error)
	zoneFor(name string) (zone, sub string, err error)
	records(zone, fieldType, sub string) ([]record, error)
	create(zone string, r record) (record, error)
	update(zone string, id int64, target string, ttl int64) error
	remove(zone string, id int64) error
	refresh(zone string) error
}

// client talks to /domain/zone through go-ovh.
//
// These are the routes caddy-dns/ovh uses, and a consumer key made for it is
// scoped to exactly these:
//
//	GET    /domain/zone/*/record
//	POST   /domain/zone/*/record
//	GET    /domain/zone/*/record/*
//	PUT    /domain/zone/*/record/*
//	DELETE /domain/zone/*/record/*
//	POST   /domain/zone/*/refresh
//
// Nothing here may rely on GET /domain/zone: the account's zone list is a right
// such a key does not have, and asking for it is a 403. zones() is the one
// command that needs it, and it says as much when it is refused.
type client struct {
	api   *ovh.Client
	cache []string
}

func newClient(c creds) (*client, error) {
	api, err := ovh.NewClient(c.endpoint, c.applicationKey, c.applicationSecret, c.consumerKey)
	if err != nil {
		return nil, err
	}
	return &client{api: api}, nil
}

// zones lists every zone on the account, the one call that needs a right a
// caddy-scoped key does not carry.
func (c *client) zones() ([]string, error) {
	if c.cache == nil {
		var zones []string
		if err := c.api.Get("/domain/zone", &zones); err != nil {
			if apiCode(err, 403) {
				return nil, errors.New("listing the account's zones needs the `GET /domain/zone` right, which a consumer key scoped for caddy's ACME challenge does not have; name the zone with --zone instead")
			}
			return nil, apiError("GET", "/domain/zone", err)
		}
		sort.Strings(zones)
		c.cache = zones
	}
	return c.cache, nil
}

// zoneFor works out which zone a name belongs to by asking, from the most
// specific candidate downwards, which of them this account actually has. That
// keeps the record routes as the only thing needed.
func (c *client) zoneFor(name string) (string, string, error) {
	candidates := zoneCandidates(name)
	tried := make([]string, 0, len(candidates))
	refused := false
	for _, candidate := range candidates {
		exists, denied, err := c.zoneExists(candidate.zone, candidate.sub)
		if err != nil {
			return "", "", err
		}
		if exists {
			return candidate.zone, candidate.sub, nil
		}
		refused = refused || denied
		tried = append(tried, candidate.zone)
	}
	// A refusal and an absence read very differently to whoever has to fix it.
	if refused {
		return "", "", fmt.Errorf("OVH refused every zone that could hold %s (tried %s): the consumer key is not scoped for the record routes, or not for these zones; pass --zone to name the zone directly",
			normalise(name), strings.Join(tried, ", "))
	}
	return "", "", fmt.Errorf("no OVH zone found for %s (tried %s); pass --zone if the key is scoped to a single zone",
		normalise(name), strings.Join(tried, ", "))
}

// zoneExists asks for a narrow slice of one zone's records. An unknown zone
// answers 404 and a zone outside the key's scope answers 403; either way the
// answer is "not this candidate", but the caller wants to tell them apart.
func (c *client) zoneExists(zone, sub string) (exists, refused bool, err error) {
	query := url.Values{}
	if sub != "" {
		query.Set("subDomain", sub)
	}
	path := zoneRecordsPath(zone, query)

	var ids []int64
	err = c.api.Get(path, &ids)
	switch {
	case err == nil:
		return true, false, nil
	case apiCode(err, 404):
		return false, false, nil
	case apiCode(err, 403):
		return false, true, nil
	default:
		return false, false, apiError("GET", path, err)
	}
}

// records lists a zone's records, narrowed by the API where it can be. An empty
// sub means the apex, so the narrowing is redone here rather than relying on the
// API to treat "subDomain=" as the apex.
func (c *client) records(zone, fieldType, sub string) ([]record, error) {
	query := url.Values{}
	if fieldType != "" {
		query.Set("fieldType", strings.ToUpper(fieldType))
	}
	if sub != "" {
		query.Set("subDomain", sub)
	}
	path := zoneRecordsPath(zone, query)

	var ids []int64
	if err := c.api.Get(path, &ids); err != nil {
		return nil, apiError("GET", path, err)
	}

	records := make([]record, 0, len(ids))
	for _, id := range ids {
		var r record
		if err := c.api.Get(recordPath(zone, id), &r); err != nil {
			return nil, apiError("GET", recordPath(zone, id), err)
		}
		if r.SubDomain != sub {
			continue
		}
		if fieldType != "" && !strings.EqualFold(r.FieldType, fieldType) {
			continue
		}
		records = append(records, r)
	}
	sort.Slice(records, func(i, j int) bool {
		if records[i].SubDomain != records[j].SubDomain {
			return records[i].SubDomain < records[j].SubDomain
		}
		if records[i].FieldType != records[j].FieldType {
			return records[i].FieldType < records[j].FieldType
		}
		return records[i].Target < records[j].Target
	})
	return records, nil
}

func (c *client) create(zone string, r record) (record, error) {
	params := struct {
		FieldType string `json:"fieldType"`
		SubDomain string `json:"subDomain"`
		Target    string `json:"target"`
		TTL       int64  `json:"ttl,omitempty"`
	}{r.FieldType, r.SubDomain, r.Target, r.TTL}

	path := zoneRecordsPath(zone, nil)
	var created record
	if err := c.api.Post(path, params, &created); err != nil {
		return record{}, apiError("POST", path, err)
	}
	return created, nil
}

func (c *client) update(zone string, id int64, target string, ttl int64) error {
	params := struct {
		Target string `json:"target"`
		TTL    int64  `json:"ttl,omitempty"`
	}{target, ttl}

	path := recordPath(zone, id)
	if err := c.api.Put(path, params, nil); err != nil {
		return apiError("PUT", path, err)
	}
	return nil
}

func (c *client) remove(zone string, id int64) error {
	path := recordPath(zone, id)
	if err := c.api.Delete(path, nil); err != nil {
		return apiError("DELETE", path, err)
	}
	return nil
}

func (c *client) refresh(zone string) error {
	path := refreshPath(zone)
	if err := c.api.Post(path, nil, nil); err != nil {
		return apiError("POST", path, err)
	}
	return nil
}

func zoneRecordsPath(zone string, query url.Values) string {
	path := fmt.Sprintf("/domain/zone/%s/record", zone)
	if len(query) > 0 {
		path += "?" + query.Encode()
	}
	return path
}

func recordPath(zone string, id int64) string {
	return fmt.Sprintf("/domain/zone/%s/record/%d", zone, id)
}

func refreshPath(zone string) string {
	return fmt.Sprintf("/domain/zone/%s/refresh", zone)
}

// apiError names the route that failed. Without it one 403 is
// indistinguishable from another, and the route is the whole diagnosis. The
// original error stays in the chain so callers can still inspect its code.
func apiError(method, path string, err error) error {
	if apiCode(err, 403) {
		return fmt.Errorf("%s %s: %w (the consumer key is not scoped for this route)", method, path, err)
	}
	return fmt.Errorf("%s %s: %w", method, path, err)
}

func apiCode(err error, code int) bool {
	var apiErr *ovh.APIError
	return errors.As(err, &apiErr) && apiErr.Code == code
}

// zoneCandidate is a zone a name might live in, and the subdomain it would have
// there.
type zoneCandidate struct {
	zone string
	sub  string
}

// zoneCandidates lists the zones a name could belong to, most specific first, so
// that a name inside a delegated subzone resolves to the subzone and a name that
// is itself a zone resolves to its apex.
func zoneCandidates(name string) []zoneCandidate {
	labels := strings.Split(normalise(name), ".")
	candidates := make([]zoneCandidate, 0, len(labels))
	for i := 0; i+2 <= len(labels); i++ {
		candidates = append(candidates, zoneCandidate{
			zone: strings.Join(labels[i:], "."),
			sub:  strings.Join(labels[:i], "."),
		})
	}
	return candidates
}

// splitName returns name's subdomain within zone, and refuses a zone that does
// not hold the name so a wrong --zone is caught rather than written to an apex.
func splitName(zone, name string) (string, error) {
	zone, name = normalise(zone), normalise(name)
	if name == zone {
		return "", nil
	}
	if !strings.HasSuffix(name, "."+zone) {
		return "", fmt.Errorf("%s is not in zone %s", name, zone)
	}
	return strings.TrimSuffix(name, "."+zone), nil
}

func normalise(name string) string {
	return strings.ToLower(strings.TrimSuffix(strings.TrimSpace(name), "."))
}
