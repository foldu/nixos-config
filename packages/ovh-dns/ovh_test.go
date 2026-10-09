package main

import (
	"testing"

	"github.com/ovh/go-ovh/ovh"
)

func TestZoneCandidates(t *testing.T) {
	tests := []struct {
		name string
		in   string
		want []zoneCandidate
	}{
		{
			name: "whole name is a zone",
			in:   "5kw.li",
			want: []zoneCandidate{{zone: "5kw.li", sub: ""}},
		},
		{
			name: "most specific first, so a delegated subzone wins",
			in:   "fish.home.5kw.li",
			want: []zoneCandidate{
				{zone: "fish.home.5kw.li", sub: ""},
				{zone: "home.5kw.li", sub: "fish"},
				{zone: "5kw.li", sub: "fish.home"},
			},
		},
		{
			name: "trailing dot and case",
			in:   "Frosch.5KW.LI.",
			want: []zoneCandidate{
				{zone: "frosch.5kw.li", sub: ""},
				{zone: "5kw.li", sub: "frosch"},
			},
		},
		{
			name: "a single label is nobody's zone",
			in:   "localhost",
			want: []zoneCandidate{},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := zoneCandidates(tt.in)
			if len(got) != len(tt.want) {
				t.Fatalf("zoneCandidates(%q) = %v, want %v", tt.in, got, tt.want)
			}
			for i := range got {
				if got[i] != tt.want[i] {
					t.Errorf("candidate %d = %v, want %v", i, got[i], tt.want[i])
				}
			}
		})
	}
}

func TestSplitName(t *testing.T) {
	tests := []struct {
		zone, name, want string
		wantErr          bool
	}{
		{zone: "5kw.li", name: "5kw.li", want: ""},
		{zone: "5kw.li", name: "frosch.5kw.li", want: "frosch"},
		{zone: "home.5kw.li", name: "fish.home.5kw.li", want: "fish"},
		{zone: "5kw.li", name: "a.b.5kw.li", want: "a.b"},
		{zone: "5kw.li", name: "Frosch.5KW.LI.", want: "frosch"},
		{zone: "5kw.li", name: "jupiter.home.5kw.li", want: "jupiter.home"},
		// A --zone that does not hold the name must not silently become the apex.
		{zone: "home.5kw.li", name: "frosch.5kw.li", wantErr: true},
		{zone: "5kw.li", name: "not5kw.li", wantErr: true},
	}
	for _, tt := range tests {
		got, err := splitName(tt.zone, tt.name)
		if tt.wantErr {
			if err == nil {
				t.Errorf("splitName(%q, %q) = %q, want an error", tt.zone, tt.name, got)
			}
			continue
		}
		if err != nil {
			t.Errorf("splitName(%q, %q): %v", tt.zone, tt.name, err)
			continue
		}
		if got != tt.want {
			t.Errorf("splitName(%q, %q) = %q, want %q", tt.zone, tt.name, got, tt.want)
		}
	}
}

func TestValidateTarget(t *testing.T) {
	tests := []struct {
		fieldType, target string
		wantErr           bool
	}{
		{fieldType: "A", target: "192.0.2.10"},
		{fieldType: "A", target: "2001:db8::1", wantErr: true},
		{fieldType: "A", target: "192.1432.4.5", wantErr: true}, // the classic typo
		{fieldType: "A", target: "not-an-ip", wantErr: true},
		{fieldType: "AAAA", target: "2001:db8::1"},
		{fieldType: "AAAA", target: "192.0.2.10", wantErr: true},
		{fieldType: "CNAME", target: "jupiter.home.5kw.li"},
		{fieldType: "CNAME", target: "two words", wantErr: true},
		{fieldType: "CNAME", target: "", wantErr: true},
		{fieldType: "TXT", target: "anything at all"},
		{fieldType: "MX", target: "10 mail.example.com"},
	}
	for _, tt := range tests {
		err := validateTarget(tt.fieldType, tt.target)
		if tt.wantErr && err == nil {
			t.Errorf("validateTarget(%q, %q) = nil, want an error", tt.fieldType, tt.target)
		}
		if !tt.wantErr && err != nil {
			t.Errorf("validateTarget(%q, %q) = %v, want nil", tt.fieldType, tt.target, err)
		}
	}
}

func TestAbsoluteTarget(t *testing.T) {
	tests := []struct {
		fieldType, target, want string
	}{
		// OVH appends the zone name to a relative target, so these must end in a dot.
		{fieldType: "CNAME", target: "saturn.home.5kw.li", want: "saturn.home.5kw.li."},
		{fieldType: "CNAME", target: "saturn.home.5kw.li.", want: "saturn.home.5kw.li."},
		{fieldType: "cname", target: "jupiter", want: "jupiter."},
		{fieldType: "NS", target: "ns110.ovh.net", want: "ns110.ovh.net."},
		{fieldType: "PTR", target: "host.example.com", want: "host.example.com."},
		{fieldType: "DNAME", target: "old.example.com", want: "old.example.com."},
		// The name is the last field, so appending to the string still lands on it.
		{fieldType: "MX", target: "10 mail.example.com", want: "10 mail.example.com."},
		{fieldType: "MX", target: "10 mail.example.com.", want: "10 mail.example.com."},
		{fieldType: "SRV", target: "0 5 443 host.example.com", want: "0 5 443 host.example.com."},
		// Everything else is literal and must not be touched.
		{fieldType: "A", target: "192.0.2.10", want: "192.0.2.10"},
		{fieldType: "AAAA", target: "2001:db8::1", want: "2001:db8::1"},
		{fieldType: "TXT", target: "v=spf1 -all", want: "v=spf1 -all"},
		{fieldType: "TXT", target: "challenge-token", want: "challenge-token"},
		{fieldType: "TXT", target: "trailing.dot.", want: "trailing.dot."},
	}
	for _, tt := range tests {
		if got := absoluteTarget(tt.fieldType, tt.target); got != tt.want {
			t.Errorf("absoluteTarget(%q, %q) = %q, want %q", tt.fieldType, tt.target, got, tt.want)
		}
	}
}

func TestSameTarget(t *testing.T) {
	tests := []struct {
		fieldType, want, have string
		same                  bool
	}{
		// OVH reports the target without the dot we sent.
		{fieldType: "CNAME", want: "saturn.home.5kw.li.", have: "saturn.home.5kw.li", same: true},
		{fieldType: "CNAME", want: "saturn.home.5kw.li.", have: "saturn.home.5kw.li.", same: true},
		{fieldType: "CNAME", want: "saturn.home.5kw.li.", have: "saturn.home.5kw.li.5kw.li", same: false},
		{fieldType: "MX", want: "10 mail.example.com.", have: "10 mail.example.com", same: true},
		// A TXT value is literal, so a dot is a real difference.
		{fieldType: "TXT", want: "token.", have: "token", same: false},
		{fieldType: "A", want: "192.0.2.10", have: "192.0.2.10", same: true},
	}
	for _, tt := range tests {
		if got := sameTarget(tt.fieldType, tt.want, tt.have); got != tt.same {
			t.Errorf("sameTarget(%q, %q, %q) = %v, want %v", tt.fieldType, tt.want, tt.have, got, tt.same)
		}
	}
}

func TestAPIErrorNamesTheRoute(t *testing.T) {
	// A 403 is only diagnosable if the message says which route was refused.
	err := apiError("GET", "/domain/zone", &ovh.APIError{Code: 403, Class: "Client::Forbidden", Message: "This call has not been granted"})
	want := `GET /domain/zone: OVHcloud API error (status code 403): Client::Forbidden: "This call has not been granted" (the consumer key is not scoped for this route)`
	if err == nil || err.Error() != want {
		t.Errorf("apiError =\n  %v\nwant\n  %q", err, want)
	}

	err = apiError("GET", "/domain/zone/5kw.li/record/7", &ovh.APIError{Code: 404, Message: "The record does not exist"})
	if want := `GET /domain/zone/5kw.li/record/7: OVHcloud API error (status code 404): "The record does not exist"`; err == nil || err.Error() != want {
		t.Errorf("apiError = %v, want %q", err, want)
	}
}

func TestAPICode(t *testing.T) {
	err := apiError("GET", "/x", &ovh.APIError{Code: 403, Message: "nope"})
	if !apiCode(err, 403) {
		t.Error("apiCode should see through the wrapping")
	}
	if apiCode(err, 404) {
		t.Error("apiCode matched the wrong code")
	}
	if apiCode(nil, 403) {
		t.Error("apiCode(nil) should be false")
	}
}
