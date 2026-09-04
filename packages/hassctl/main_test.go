package main

import (
	"net"
	"os"
	"path/filepath"
	"testing"
)

func TestMagicPacket(t *testing.T) {
	mac, err := net.ParseMAC("00:11:22:33:44:55")
	if err != nil {
		t.Fatal(err)
	}
	pkt := magicPacket(mac)
	if len(pkt) != 102 {
		t.Fatalf("len = %d, want 102", len(pkt))
	}
	for i := 0; i < 6; i++ {
		if pkt[i] != 0xff {
			t.Fatalf("preamble byte %d = %#x, want 0xff", i, pkt[i])
		}
	}
	want := []byte{0x00, 0x11, 0x22, 0x33, 0x44, 0x55}
	for i := 0; i < 16; i++ {
		off := 6 + i*6
		for j := 0; j < 6; j++ {
			if pkt[off+j] != want[j] {
				t.Fatalf("mac copy %d byte %d = %#x, want %#x", i, j, pkt[off+j], want[j])
			}
		}
	}
}

func TestLoadConfig(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "config.yaml")
	content := `
token: "sekret"
listen: "127.0.0.1:9999"
wake:
  localAddr: "192.168.8.116"
  broadcast: "192.168.8.255"
devices:
  jupiter:
    mac: "00:11:22:33:44:55"
    poweroff:
      addr: "192.168.8.107:22"
  saturn:
    status: "192.168.8.149:22"
`
	if err := os.WriteFile(path, []byte(content), 0o600); err != nil {
		t.Fatal(err)
	}

	cfg, err := loadConfig(path)
	if err != nil {
		t.Fatal(err)
	}
	if cfg.Token != "sekret" {
		t.Fatalf("token = %q, want sekret", cfg.Token)
	}
	if cfg.Listen != "127.0.0.1:9999" {
		t.Fatalf("listen = %q", cfg.Listen)
	}

	j, ok := cfg.Devices["jupiter"]
	if !ok {
		t.Fatal("jupiter not configured")
	}
	if j.MAC.String() != "00:11:22:33:44:55" {
		t.Fatalf("jupiter mac = %v", j.MAC)
	}
	if j.Status != "192.168.8.107:22" { // defaults to poweroff.addr
		t.Fatalf("jupiter status = %q, want default from poweroff addr", j.Status)
	}
	// per-device wake fields fall back to the top-level defaults
	if j.Wake.LocalAddr != "192.168.8.116" || j.Wake.Broadcast != "192.168.8.255" {
		t.Fatalf("jupiter wake = %+v", j.Wake)
	}
	// top-level defaults apply
	if j.Poweroff.User != "barnabas" {
		t.Fatalf("jupiter poweroff user = %q, want default barnabas", j.Poweroff.User)
	}
	if j.Poweroff.SSHKey != "/etc/hassctl/keys/poweroff" {
		t.Fatalf("jupiter poweroff sshKey = %q", j.Poweroff.SSHKey)
	}

	s, ok := cfg.Devices["saturn"]
	if !ok {
		t.Fatal("saturn not configured")
	}
	if len(s.MAC) != 0 {
		t.Fatalf("saturn mac = %v, want none", s.MAC)
	}
	if s.Status != "192.168.8.149:22" {
		t.Fatalf("saturn status = %q", s.Status)
	}
}

func TestLoadConfigRequiresToken(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "config.yaml")
	if err := os.WriteFile(path, []byte("devices: {}\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := loadConfig(path); err == nil {
		t.Fatal("expected error for missing token")
	}
}
