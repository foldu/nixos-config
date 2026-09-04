package main

import (
	"net"
	"time"
)

// up reports whether the device is reachable. A TCP connect to its sshd is
// used instead of ICMP: a sleeping NIC does not answer TCP, so this is a true
// liveness signal that does not depend on firewall/ICMP policy, and it needs
// no external `ping` binary.
func up(addr string) bool {
	conn, err := net.DialTimeout("tcp", addr, time.Second)
	if err != nil {
		return false
	}
	conn.Close()
	return true
}
