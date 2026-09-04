package main

import (
	"errors"
	"fmt"
	"net"
	"os"
	"strings"
	"time"

	"github.com/spf13/viper"
)

// WakeConfig controls how magic packets are sent. Per-device sections may
// override any field; the top-level `wake` section provides the defaults.
type WakeConfig struct {
	LocalAddr string // source IP to bind (eth0 on the home LAN)
	Broadcast string // directed broadcast of the target subnet
}

// PoweroffConfig controls the SSH poweroff. Per-device sections may override
// any field; the top-level `poweroff` section provides the defaults.
type PoweroffConfig struct {
	Addr    string // host:port to connect to (the machine being powered off)
	User    string
	SSHKey  string        // private key path (forced-command restricted on the target)
	Timeout time.Duration // ssh handshake timeout
}

// Device is a fully-resolved device entry (defaults applied).
type Device struct {
	ID       string
	MAC      net.HardwareAddr // empty => wake not supported for this device
	Status   string           // TCP liveness target; defaults to Poweroff.Addr
	Wake     WakeConfig
	Poweroff PoweroffConfig
}

// Config is the fully-resolved runtime configuration.
type Config struct {
	Listen  string
	Token   string
	Devices map[string]*Device
}

func firstNonEmpty(vals ...string) string {
	for _, v := range vals {
		if v != "" {
			return v
		}
	}
	return ""
}

// defaultConfigPath returns the explicit config file path from HASSCTL_CONFIG,
// or the default location (/etc/hassctl/config.yaml).
func defaultConfigPath() string {
	if p := os.Getenv("HASSCTL_CONFIG"); p != "" {
		return p
	}
	return "/etc/hassctl/config.yaml"
}

// loadConfig builds the runtime configuration from viper: a YAML config file
// (default /etc/hassctl/config.yaml, overridable via HASSCTL_CONFIG) with
// defaults in code and every key overridable via HASSCTL_* environment
// variables (e.g. HASSCTL_TOKEN, HASSCTL_DEVICES_JUPITER_MAC).
func loadConfig(path string) (*Config, error) {
	v := viper.New()
	v.SetConfigType("yaml")
	v.SetConfigFile(path)

	// defaults (all overridable per-device or via env)
	v.SetDefault("listen", "172.25.74.230:8080")
	v.SetDefault("wake.localAddr", "192.168.8.116")
	v.SetDefault("wake.broadcast", "192.168.8.255")
	v.SetDefault("poweroff.user", "barnabas")
	v.SetDefault("poweroff.sshKey", "/etc/hassctl/keys/poweroff")
	v.SetDefault("poweroff.timeout", "5s")

	v.SetEnvPrefix("HASSCTL")
	v.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
	v.AutomaticEnv()

	if err := v.ReadInConfig(); err != nil {
		var notFound viper.ConfigFileNotFoundError
		if !errors.As(err, &notFound) && !os.IsNotExist(err) {
			return nil, fmt.Errorf("read config %s: %w", path, err)
		}
	}

	timeout, err := time.ParseDuration(v.GetString("poweroff.timeout"))
	if err != nil {
		return nil, fmt.Errorf("poweroff.timeout: %w", err)
	}

	cfg := &Config{
		Listen:  v.GetString("listen"),
		Token:   v.GetString("token"),
		Devices: map[string]*Device{},
	}
	if cfg.Token == "" {
		return nil, errors.New("token is required (config 'token' or env HASSCTL_TOKEN)")
	}

	for id := range v.GetStringMap("devices") {
		d := &Device{ID: id}
		if macStr := v.GetString("devices." + id + ".mac"); macStr != "" {
			mac, err := net.ParseMAC(macStr)
			if err != nil {
				return nil, fmt.Errorf("devices.%s.mac: %w", id, err)
			}
			d.MAC = mac
		}
		d.Status = firstNonEmpty(
			v.GetString("devices."+id+".status"),
			v.GetString("devices."+id+".poweroff.addr"),
		)

		d.Wake = WakeConfig{
			LocalAddr: firstNonEmpty(
				v.GetString("devices."+id+".wake.localAddr"),
				v.GetString("wake.localAddr"),
			),
			Broadcast: firstNonEmpty(
				v.GetString("devices."+id+".wake.broadcast"),
				v.GetString("wake.broadcast"),
			),
		}
		d.Poweroff = PoweroffConfig{
			Addr:    v.GetString("devices." + id + ".poweroff.addr"),
			User:    firstNonEmpty(v.GetString("devices."+id+".poweroff.user"), v.GetString("poweroff.user")),
			SSHKey:  firstNonEmpty(v.GetString("devices."+id+".poweroff.sshKey"), v.GetString("poweroff.sshKey")),
			Timeout: timeout,
		}
		cfg.Devices[id] = d
	}

	return cfg, nil
}
