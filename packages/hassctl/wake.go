package main

import (
	"fmt"
	"net"
	"strconv"
	"syscall"
)

// magicPacket builds the Wake-on-LAN magic packet: 6x 0xff followed by the
// target MAC repeated 16 times (102 bytes total).
func magicPacket(mac net.HardwareAddr) []byte {
	pkt := make([]byte, 102)
	for i := 0; i < 6; i++ {
		pkt[i] = 0xff
	}
	for i := 0; i < 16; i++ {
		copy(pkt[6+i*6:], mac)
	}
	return pkt
}

// wakePorts are the destination UDP ports for the magic packet. NIC WoL
// matchers sniff for the packet pattern regardless of port, so the choice
// only matters for OS-level wake services — which listen on 7 or 9. Sending
// to both covers every case with no configuration.
var wakePorts = []int{9, 7}

// sendWake sends the magic packet as a UDP broadcast for the given device.
//
// The socket is bound to the configured local address and targets the
// directed broadcast of the device's subnet. This is deliberate: a limited
// broadcast (255.255.255.255) could be routed out of the netbird wireguard
// interface instead, and the magic packet would vanish into the mesh.
func sendWake(mac net.HardwareAddr, w WakeConfig) error {
	local, err := net.ResolveUDPAddr("udp", net.JoinHostPort(w.LocalAddr, "0"))
	if err != nil {
		return fmt.Errorf("resolve local addr: %w", err)
	}
	pkt := magicPacket(mac)
	for _, port := range wakePorts {
		if err := sendWakeTo(local, w.Broadcast, port, pkt); err != nil {
			return err
		}
	}
	return nil
}

// sendWakeTo sends one magic packet to broadcast:port from local.
func sendWakeTo(local *net.UDPAddr, broadcast string, port int, pkt []byte) error {
	remote, err := net.ResolveUDPAddr("udp", net.JoinHostPort(broadcast, strconv.Itoa(port)))
	if err != nil {
		return fmt.Errorf("resolve broadcast: %w", err)
	}
	conn, err := net.DialUDP("udp", local, remote)
	if err != nil {
		return err
	}
	defer conn.Close()
	// net already sets SO_BROADCAST for broadcast destinations; set it
	// explicitly so the intent (and the dependency on it) is visible.
	if raw, err := conn.SyscallConn(); err == nil {
		raw.Control(func(fd uintptr) {
			_ = syscall.SetsockoptInt(int(fd), syscall.SOL_SOCKET, syscall.SO_BROADCAST, 1)
		})
	}
	_, err = conn.Write(pkt)
	return err
}
