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
	records(zone, fieldType, sub string) ([]record, error)
	create(zone string, r record) (record, error)
	update(zone string, id int64, target string, ttl int64) error
	remove(zone string, id int64) error
	refresh(zone string) error
}

// client talks to /domain/zone through go-ovh. These are the routes
// caddy-dns/ovh uses, so a consumer key that already covers the ACME challenge
// covers this too.
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

func (c *client) zones() ([]string, error) {
	if c.cache == nil {
		var zones []string
		if err := c.api.Get("/domain/zone", &zones); err != nil {
			return nil, apiError(err)
		}
		sort.Strings(zones)
		c.cache = zones
	}
	return c.cache, nil
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
	path := fmt.Sprintf("/domain/zone/%s/record", zone)
	if len(query) > 0 {
		path += "?" + query.Encode()
	}

	var ids []int64
	if err := c.api.Get(path, &ids); err != nil {
		return nil, apiError(err)
	}

	records := make([]record, 0, len(ids))
	for _, id := range ids {
		var r record
		if err := c.api.Get(fmt.Sprintf("/domain/zone/%s/record/%d", zone, id), &r); err != nil {
			return nil, apiError(err)
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

	var created record
	if err := c.api.Post(fmt.Sprintf("/domain/zone/%s/record", zone), params, &created); err != nil {
		return record{}, apiError(err)
	}
	return created, nil
}

func (c *client) update(zone string, id int64, target string, ttl int64) error {
	params := struct {
		Target string `json:"target"`
		TTL    int64  `json:"ttl,omitempty"`
	}{target, ttl}

	if err := c.api.Put(fmt.Sprintf("/domain/zone/%s/record/%d", zone, id), params, nil); err != nil {
		return apiError(err)
	}
	return nil
}

func (c *client) remove(zone string, id int64) error {
	if err := c.api.Delete(fmt.Sprintf("/domain/zone/%s/record/%d", zone, id), nil); err != nil {
		return apiError(err)
	}
	return nil
}

func (c *client) refresh(zone string) error {
	if err := c.api.Post(fmt.Sprintf("/domain/zone/%s/refresh", zone), nil, nil); err != nil {
		return apiError(err)
	}
	return nil
}

// apiError turns an OVH reply into something readable. A 403 is worth spelling
// out because it is usually the consumer key's scope rather than a mistake in
// the request.
func apiError(err error) error {
	var apiErr *ovh.APIError
	if errors.As(err, &apiErr) {
		if apiErr.Code == 403 {
			return fmt.Errorf("OVH refused the call: %s (check the keys are valid and the consumer key is scoped for this route)", apiErr.Message)
		}
		return fmt.Errorf("OVH API %d: %s", apiErr.Code, apiErr.Message)
	}
	return err
}

// pickZone returns the longest zone that name belongs to, so a name in a
// delegated subzone resolves to that subzone rather than its parent.
func pickZone(zones []string, name string) (string, error) {
	name = normalise(name)
	best := ""
	for _, zone := range zones {
		if name == zone || strings.HasSuffix(name, "."+zone) {
			if len(zone) > len(best) {
				best = zone
			}
		}
	}
	if best == "" {
		return "", fmt.Errorf("%s is not in any zone on this account (try 'ovh-dns zones')", name)
	}
	return best, nil
}

// relativeName returns name's subdomain within zone: "www" for www.example.com,
// and "" for the apex.
func relativeName(zone, name string) string {
	name = normalise(name)
	if name == zone {
		return ""
	}
	return strings.TrimSuffix(name, "."+zone)
}

func normalise(name string) string {
	return strings.ToLower(strings.TrimSuffix(strings.TrimSpace(name), "."))
}
