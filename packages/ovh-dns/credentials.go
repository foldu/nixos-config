package main

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/getsops/sops/v3/decrypt"
	"gopkg.in/yaml.v3"
)

// creds is the OVH API credential set stored under caddy/env.
type creds struct {
	endpoint          string
	applicationKey    string
	applicationSecret string
	consumerKey       string
}

// loadCredentials decrypts a sops file in-process and returns the OVH_* values
// from its caddy/env entry. sops is used as a library so there is no sops
// binary to install, and the age key is found the usual way (SOPS_AGE_KEY_FILE,
// SOPS_AGE_KEY, or ~/.config/sops/age/keys.txt).
func loadCredentials(file string) (creds, error) {
	encrypted, err := os.ReadFile(file)
	if err != nil {
		return creds{}, err
	}
	plaintext, err := decrypt.Data(encrypted, formatForPath(file))
	if err != nil {
		return creds{}, fmt.Errorf("cannot decrypt %s (is the sops key available?): %w", file, err)
	}
	text, err := extractEnv(plaintext)
	if err != nil {
		return creds{}, fmt.Errorf("%s: %w", file, err)
	}

	vars := parseEnv(text)
	var missing []string
	for _, key := range requiredKeys {
		if vars[key] == "" {
			missing = append(missing, key)
		}
	}
	if len(missing) > 0 {
		return creds{}, fmt.Errorf("%s has no %s under caddy/env", file, strings.Join(missing, " "))
	}

	endpoint := vars["OVH_ENDPOINT"]
	if endpoint == "" {
		endpoint = os.Getenv("OVH_ENDPOINT")
	}
	if endpoint == "" {
		endpoint = defaultEndpoint
	}

	return creds{
		endpoint:          endpoint,
		applicationKey:    vars["OVH_APPLICATION_KEY"],
		applicationSecret: vars["OVH_APPLICATION_SECRET"],
		consumerKey:       vars["OVH_CONSUMER_KEY"],
	}, nil
}

// extractEnv returns the caddy/env value of a decrypted sops document. The
// document is parsed properly rather than grepped, so a value stored as a block
// scalar and one stored as a single escaped line read the same.
func extractEnv(plaintext []byte) (string, error) {
	var doc struct {
		Caddy struct {
			Env string `yaml:"env"`
		} `yaml:"caddy"`
	}
	if err := yaml.Unmarshal(plaintext, &doc); err != nil {
		return "", fmt.Errorf("cannot read the decrypted document: %w", err)
	}
	if doc.Caddy.Env == "" {
		return "", errors.New("the decrypted document has no caddy/env value")
	}
	return doc.Caddy.Env, nil
}

// formatForPath names the sops store to use. sops falls back to "binary" for
// unknown extensions, which would be wrong here, so YAML is the default the way
// sops-nix writes secrets.
func formatForPath(path string) string {
	switch strings.ToLower(filepath.Ext(path)) {
	case ".json":
		return "json"
	case ".ini":
		return "ini"
	case ".env":
		return "dotenv"
	default:
		return "yaml"
	}
}

// parseEnv reads KEY=value lines. It is deliberately not a shell: values are
// taken literally, and only names in the OVH_ namespace survive, so the
// unrelated caddy secrets in the same file are never used.
func parseEnv(text string) map[string]string {
	vars := make(map[string]string)
	scanner := bufio.NewScanner(strings.NewReader(text))
	scanner.Buffer(make([]byte, 0, 64*1024), 1024*1024)
	for scanner.Scan() {
		line := strings.TrimSuffix(scanner.Text(), "\r")
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		key, value, ok := strings.Cut(strings.TrimPrefix(line, "export "), "=")
		key = strings.TrimSpace(key)
		if !ok || !validKey(key) {
			continue
		}
		vars[key] = unquote(value)
	}
	return vars
}

func validKey(key string) bool {
	if !strings.HasPrefix(key, "OVH_") {
		return false
	}
	for _, r := range key {
		switch {
		case r >= 'A' && r <= 'Z', r >= 'a' && r <= 'z', r >= '0' && r <= '9', r == '_':
		default:
			return false
		}
	}
	return true
}

func unquote(value string) string {
	if len(value) >= 2 {
		first, last := value[0], value[len(value)-1]
		if first == last && (first == '"' || first == '\'') {
			return value[1 : len(value)-1]
		}
	}
	return value
}

// resolveSecretsFile uses an absolute path as given and looks a relative one up
// in the working directory and its parents, the way git finds .git.
func resolveSecretsFile(path string) (string, error) {
	if filepath.IsAbs(path) {
		if !readable(path) {
			return "", fmt.Errorf("no readable secrets file at %s", path)
		}
		return path, nil
	}
	dir, err := os.Getwd()
	if err != nil {
		return "", err
	}
	start := dir
	for {
		if candidate := filepath.Join(dir, path); readable(candidate) {
			return candidate, nil
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			return "", fmt.Errorf("no %q in %s or any parent directory; pass --secrets-file", path, start)
		}
		dir = parent
	}
}

func readable(path string) bool {
	f, err := os.Open(path)
	if err != nil {
		return false
	}
	f.Close()
	return true
}
