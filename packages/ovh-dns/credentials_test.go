package main

import (
	"os"
	"path/filepath"
	"testing"
)

func TestParseEnv(t *testing.T) {
	tests := []struct {
		name string
		in   string
		want map[string]string
	}{
		{
			name: "quotes, export and unrelated secrets",
			in: `# caddy's environment
export OVH_APPLICATION_KEY='app-key-value'
OVH_APPLICATION_SECRET="app-secret-value"
OVH_CONSUMER_KEY=consumer-key-value
CLOUDFLARE_API_TOKEN=must-not-leak
`,
			want: map[string]string{
				"OVH_APPLICATION_KEY":    "app-key-value",
				"OVH_APPLICATION_SECRET": "app-secret-value",
				"OVH_CONSUMER_KEY":       "consumer-key-value",
			},
		},
		{
			name: "carriage returns",
			in:   "OVH_APPLICATION_KEY=one\r\nOVH_CONSUMER_KEY=two\r\n",
			want: map[string]string{"OVH_APPLICATION_KEY": "one", "OVH_CONSUMER_KEY": "two"},
		},
		{
			name: "endpoint is kept",
			in:   "OVH_ENDPOINT=ovh-ca\nOVH_CONSUMER_KEY=c\n",
			want: map[string]string{"OVH_ENDPOINT": "ovh-ca", "OVH_CONSUMER_KEY": "c"},
		},
		{
			name: "keys outside the OVH_ namespace are dropped",
			in:   "CLOUDFLARE_API_TOKEN=t\nOVHA=x\nOVH-A=y\nOVH =z\n",
			want: map[string]string{},
		},
		{
			name: "whitespace around the key",
			in:   "  OVH_CONSUMER_KEY  =c\n",
			want: map[string]string{"OVH_CONSUMER_KEY": "c"},
		},
		{
			name: "lines without an = are ignored",
			in:   "nonsense\n\n# comment\nOVH_CONSUMER_KEY=c\n",
			want: map[string]string{"OVH_CONSUMER_KEY": "c"},
		},
		{
			name: "a value containing = keeps the rest",
			in:   "OVH_CONSUMER_KEY=a=b\n",
			want: map[string]string{"OVH_CONSUMER_KEY": "a=b"},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := parseEnv(tt.in)
			if len(got) != len(tt.want) {
				t.Fatalf("parseEnv = %v, want %v", got, tt.want)
			}
			for key, want := range tt.want {
				if got[key] != want {
					t.Errorf("parseEnv[%q] = %q, want %q", key, got[key], want)
				}
			}
		})
	}
}

func TestExtractEnv(t *testing.T) {
	tests := []struct {
		name    string
		in      string
		want    string
		wantErr bool
	}{
		{
			name: "block scalar",
			in:   "caddy:\n    env: |\n        OVH_APPLICATION_KEY=k\n        OVH_CONSUMER_KEY=c\n",
			want: "OVH_APPLICATION_KEY=k\nOVH_CONSUMER_KEY=c\n",
		},
		{
			name: "single escaped line",
			in:   "caddy:\n    env: \"OVH_APPLICATION_KEY=k\\nOVH_CONSUMER_KEY=c\"\n",
			want: "OVH_APPLICATION_KEY=k\nOVH_CONSUMER_KEY=c",
		},
		{
			name: "json document",
			in:   `{"caddy":{"env":"OVH_APPLICATION_KEY=k\n"}}`,
			want: "OVH_APPLICATION_KEY=k\n",
		},
		{
			name: "other keys are ignored",
			in:   "gitlab:\n    token: x\ncaddy:\n    env: OVH_CONSUMER_KEY=c\n",
			want: "OVH_CONSUMER_KEY=c",
		},
		{
			name:    "no caddy/env",
			in:      "caddy:\n    other: x\n",
			wantErr: true,
		},
		{
			name:    "not a document",
			in:      "\tthis: is: not: yaml\n",
			wantErr: true,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := extractEnv([]byte(tt.in))
			if tt.wantErr {
				if err == nil {
					t.Fatalf("extractEnv = %q, want an error", got)
				}
				return
			}
			if err != nil {
				t.Fatalf("extractEnv: %v", err)
			}
			if got != tt.want {
				t.Errorf("extractEnv = %q, want %q", got, tt.want)
			}
			if vars := parseEnv(got); len(vars) == 0 {
				t.Errorf("parseEnv found nothing in %q", got)
			}
		})
	}
}

func TestFormatForPath(t *testing.T) {
	tests := map[string]string{
		"secrets/secrets.yaml": "yaml",
		"secrets.yaml":         "yaml",
		"SECRETS.YAML":         "yaml",
		"secrets.json":         "json",
		"secrets.ini":          "ini",
		"secrets.env":          "dotenv",
		"secrets":              "yaml", // unknown extension: sops would say binary
	}
	for path, want := range tests {
		if got := formatForPath(path); got != want {
			t.Errorf("formatForPath(%q) = %q, want %q", path, got, want)
		}
	}
}

func TestResolveSecretsFile(t *testing.T) {
	t.Setenv("OVH_DNS_SECRETS_FILE", "")
	dir := t.TempDir()
	path := filepath.Join(dir, "secrets", "secrets.yaml")
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte("caddy:\n    env: |\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	t.Chdir(dir)

	got, err := resolveSecretsFile(defaultSecretsFile)
	if err != nil {
		t.Fatalf("resolveSecretsFile: %v", err)
	}
	if got != path {
		t.Errorf("resolveSecretsFile = %q, want %q", got, path)
	}

	if _, err := resolveSecretsFile(filepath.Join(t.TempDir(), "nope.yaml")); err == nil {
		t.Error("a missing absolute path should fail")
	}

	t.Chdir(t.TempDir())
	if _, err := resolveSecretsFile(defaultSecretsFile); err == nil {
		t.Error("a missing relative path should fail")
	}
}

func TestValidKey(t *testing.T) {
	valid := []string{"OVH_APPLICATION_KEY", "OVH_ENDPOINT", "OVH_A1"}
	invalid := []string{"", "APPLICATION_KEY", "OVH-APPLICATION", "OVH APPLICATION", "ovh_key", "OVH_K;rm"}
	for _, key := range valid {
		if !validKey(key) {
			t.Errorf("validKey(%q) = false, want true", key)
		}
	}
	for _, key := range invalid {
		if validKey(key) {
			t.Errorf("validKey(%q) = true, want false", key)
		}
	}
}
