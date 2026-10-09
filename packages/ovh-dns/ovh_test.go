package main

import (
	"testing"

	"github.com/ovh/go-ovh/ovh"
)

func TestPickZone(t *testing.T) {
	zones := []string{"5kw.li", "home.5kw.li", "lab.home.5kw.li", "example.com"}

	tests := []struct {
		name    string
		in      string
		want    string
		wantErr bool
	}{
		{name: "zone itself", in: "5kw.li", want: "5kw.li"},
		{name: "record in the parent zone", in: "frosch.5kw.li", want: "5kw.li"},
		{name: "delegated subzone wins", in: "fish.home.5kw.li", want: "home.5kw.li"},
		{name: "deepest subzone wins", in: "x.lab.home.5kw.li", want: "lab.home.5kw.li"},
		{name: "trailing dot and case", in: "Frosch.5KW.LI.", want: "5kw.li"},
		{name: "unrelated zone", in: "example.com", want: "example.com"},
		{name: "not on this account", in: "fish.elsewhere.net", wantErr: true},
		{name: "suffix but not a label", in: "not5kw.li", wantErr: true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := pickZone(zones, tt.in)
			if tt.wantErr {
				if err == nil {
					t.Fatalf("pickZone(%q) = %q, want an error", tt.in, got)
				}
				return
			}
			if err != nil {
				t.Fatalf("pickZone: %v", err)
			}
			if got != tt.want {
				t.Errorf("pickZone(%q) = %q, want %q", tt.in, got, tt.want)
			}
		})
	}
}

func TestRelativeName(t *testing.T) {
	tests := []struct {
		zone, name, want string
	}{
		{"5kw.li", "5kw.li", ""},
		{"5kw.li", "frosch.5kw.li", "frosch"},
		{"home.5kw.li", "fish.home.5kw.li", "fish"},
		{"5kw.li", "a.b.5kw.li", "a.b"},
		{"5kw.li", "Frosch.5KW.LI.", "frosch"},
	}
	for _, tt := range tests {
		if got := relativeName(tt.zone, tt.name); got != tt.want {
			t.Errorf("relativeName(%q, %q) = %q, want %q", tt.zone, tt.name, got, tt.want)
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

func TestAPIErrorExplainsForbidden(t *testing.T) {
	err := apiError(&ovh.APIError{Code: 403, Class: "Client::Forbidden", Message: "This call has not been granted"})
	want := "OVH refused the call: This call has not been granted (check the keys are valid and the consumer key is scoped for this route)"
	if err == nil || err.Error() != want {
		t.Errorf("apiError = %v, want %q", err, want)
	}

	err = apiError(&ovh.APIError{Code: 404, Message: "The record does not exist"})
	if err == nil || err.Error() != "OVH API 404: The record does not exist" {
		t.Errorf("apiError = %v", err)
	}
}
