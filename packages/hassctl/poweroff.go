package main

import (
	"errors"
	"fmt"
	"log"
	"net"
	"os"

	"golang.org/x/crypto/ssh"
)

// poweroff shuts a device down via SSH.
//
// The device's authorized_keys entry for the poweroff key is a forced command
// (`sudo poweroff`) with `restrict`, so the requested command is ignored and
// the key can do nothing else — nothing interesting can be exfiltrated with
// it. Host key verification is deliberately skipped for the same reason: even
// a MITM'd session can only trigger a poweroff, which the token-authenticated
// caller is already allowed to request.
//
// Failure semantics: connection-level failures (refused, unreachable, dial
// timeout — see unreachable) and a connection dropped mid-run (machine
// powering down) are treated as success; an SSH-level failure (notably bad
// auth or a bad handshake, which indicate misconfiguration) or a session
// that exits with a real status is a genuine failure returned to the caller.
func poweroff(d *Device) error {
	key, err := os.ReadFile(d.Poweroff.SSHKey)
	if err != nil {
		return fmt.Errorf("read ssh key: %w", err)
	}
	signer, err := ssh.ParsePrivateKey(key)
	if err != nil {
		return fmt.Errorf("parse ssh key: %w", err)
	}

	client, err := ssh.Dial("tcp", d.Poweroff.Addr, &ssh.ClientConfig{
		User:            d.Poweroff.User,
		Auth:            []ssh.AuthMethod{ssh.PublicKeys(signer)},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(), // see above
		Timeout:         d.Poweroff.Timeout,
	})
	if err != nil {
		if unreachable(err) {
			// connection-level failure: already off (or a network problem) —
			// idempotent success
			log.Printf("poweroff %s: target unreachable (%v), treating as already off", d.ID, err)
			return nil
		}
		// SSH-level failure (auth, handshake, protocol): the target may well
		// still be running, so this must surface as an error, not as a
		// silent "already off" success.
		return fmt.Errorf("poweroff %s: dial %s: %w", d.ID, d.Poweroff.Addr, err)
	}
	defer client.Close()

	sess, err := client.NewSession()
	if err != nil {
		return err
	}
	defer sess.Close()

	if err := sess.Run(""); err != nil { // forced command runs regardless of this
		var exitErr *ssh.ExitError
		if errors.As(err, &exitErr) {
			return fmt.Errorf("poweroff failed on %s: %w", d.ID, exitErr)
		}
		// connection dropped => the machine is going down; that's the goal
	}
	return nil
}

// unreachable reports whether err is a connection-level failure that is
// consistent with the target already being powered off: connection refused,
// host/network unreachable, a dial timeout, or the interface being down.
//
// SSH-level errors (auth, handshake, protocol) deliberately do NOT count:
// those indicate misconfiguration and must surface as real failures, not
// silent "already off" successes. DNS failures are likewise treated as
// misconfiguration: the target was never reached, so the error says nothing
// about its power state.
func unreachable(err error) bool {
	var dnsErr *net.DNSError
	if errors.As(err, &dnsErr) {
		return false
	}
	var netErr net.Error // covers net.OpError: refused, unreachable, timeouts
	return errors.As(err, &netErr)
}
