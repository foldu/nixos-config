# winvm

Control surface for the Windows test guest on jupiter. Plain `virsh` underneath;
this exists so an agent can drive the VM with a handful of non-interactive
commands instead of remembering libvirt flags.

## Shape

- **Host GPU stays on the host.** The discrete card (`1002:7550`, IOMMU group 14)
  is `amdgpu` and stays that way: niri, Steam/Proton, LACT.
- **The iGPU is the guest's only graphics device.** `0000:75:00.0` (`1002:13c0`,
  group 28, `boot_vga=0`, no connectors) is bound to `vfio-pci` from the initrd,
  so the host never initializes it and there is nothing to reset or detach later.
  `amdgpu` is in jupiter's initrd, hence the `softdep amdgpu pre: vfio-pci`.
- **Its HDMI audio function is not passed.** `1002:1640` sits in its own group
  (29); nothing in the test setup needs HDMI audio out of the motherboard.
- **No emulated display.** With a second adapter present, adapter selection
  inside Windows becomes ambiguous — exactly what you don't want when testing a
  GPU-accelerated terminal. After `winvm gpu on` the iGPU is the only one.

## No Microsoft account

The consumer ISO normally insists on a Microsoft account at OOBE (and Home has no
way out at all). The checked-in [autounattend.xml](./autounattend.xml) never gets
there: `SkipMachineOOBE` and `SkipUserOOBE` plus a `LocalAccounts` entry create a
local administrator and boot straight to a desktop. `--unattended` from virt-install
would do the same (it delegates to osinfo-db's script, which skips OOBE too) but it
cannot enable SSH, which is the part that matters here.

Windows' own hardware checks are bypassed in the same file (`LabConfig`), because
the VM has a TPM but no Secure Boot.

## One-time setup

```sh
export WINVM_ISO=~/isos/win11.iso     # the ordinary consumer ISO is fine
export WINVM_PASSWORD='...'           # local admin password

winvm install                         # builds the medium, starts the install
winvm console                         # optional: watch it, or plug a monitor
                                      # into the motherboard HDMI -- that output
                                      # is the guest's
```

`install` generates `~/.local/state/winvm/id_ed25519` (override with
`WINVM_MEDIA_DIR`), writes the answer file and first-logon script next to it,
bundles those with the VirtIO drivers into one medium, and starts the install.
Nothing to click: the edition comes from `WINVM_IMAGE_NAME` (default
`Windows 11 Pro`, chosen with the generic install key, so it is unactivated), the
disk is wiped and partitioned, and at first logon `winvm-bootstrap.ps1` enables
OpenSSH with that key, enables RDP, installs the guest agent, and writes the
adapter inventory to `C:\winvm-adapters.txt`.

Then:

```sh
winvm down
winvm gpu on                          # attach the iGPU (the emulated display stays)
winvm up
winvm ps 'Get-PnpDevice -Class Display | Format-Table | Out-String'
```

Dropping the emulated display is a separate step, and only worth taking once the
guest's own GPU driver is working: a guest with no display device at all did not
finish booting here, so `winvm display off` is deliberate rather than part of
`gpu on`.

`winvm ps` encodes the script, so quotes and pipes survive the trip; `winvm ssh`
passes its arguments straight through and Windows sshd reassembles them, so do not
nest `cmd /c` (the outer shell is already cmd) and prefer `winvm ps` for anything
involving quotes.

If the install goes sideways, `WINVM_ATTENDED=1 winvm install` skips the answer
file so you can drive Setup by hand over `winvm console`; `winvm bootstrap` prints
the first-logon script for pasting into an existing guest.

## Debloating

The medium carries Win11Debloat, pinned to a release and vendored in the flake
(`fetchFromGitHub` at tag `2026.10.30`; the release `.zip` stores backslash path
separators and will not unpack). Nothing at install time downloads it, so there is
no `irm https://debloat.raphi.re/ | iex` in the chain.

At first logon the bootstrap runs it with a deliberately conservative flag set —
telemetry, Bing/Copilot/Recall/Click-to-do, widgets, lock-screen tips, 365 ads,
companion-app auto-install, Delivery Optimization, fast startup, and the default
app removal. It does **not** touch Defender, Windows Update, Edge, or services, and
deliberately leaves driver updates alone. That keeps the guest representative of
Windows, which matters when the point is testing software on Windows.

```sh
winvm debloat --dry-run              # -WhatIf: prints the intended changes
winvm debloat                        # applies them to the running guest
WINVM_DEBLOAT=0 winvm install        # skip it for a stock guest
```

`winvm debloat` copies the vendored tree to `C:\ProgramData\win11debloat` and runs
it there, so it also works on a guest installed before this existed. Logs come back
on stdout; the script's own `Stop-Transcript` complains when it has no transcript
host, which is harmless.

App removals are reversible through the Microsoft Store, settings are registry
policies. `-SkipExplorerRestart` is set, so most changes land at the next sign-in —
which is the next boot anyway if you follow this with `winvm gpu on`.

## Per-test state

```sh
winvm down && winvm snapshot base    # once, after the guest is set up and clean
winvm reset                          # destroy -> revert to base -> start
```

Host devices block live snapshots, so snapshots are taken with the domain shut
off; `reset` therefore always does a full boot. If `destroy`+`start` turns out to
wedge the iGPU (APUs have no FLR), `winvm save` / `winvm unsave` give a
state-preserving path that skips guest-side re-initialization — run the loop
below before relying on either.

## Acceptance test (do this before trusting the guest)

```sh
for i in $(seq 1 10); do
  winvm reset
  winvm ssh -- cmd /c echo booted $i
done
```

If the iGPU fails to re-acquire on the second start, vfio logs
`Unable to reset device` and the domain won't start until the host reboots. That
is the one genuinely risky part of iGPU passthrough; the loop is the go/no-go.

## Caveats

- **Don't measure GPU performance over RDP.** Many GPU-accelerated apps turn
  acceleration off when `GetSystemMetrics(SM_REMOTESESSION)` is set. Use the
  motherboard HDMI output for the real thing, SSH for automation, RDP for
  convenience only.
- **No `virsh screenshot`.** Without an emulated graphics device there is no
  framebuffer to grab; capture inside the guest (the test harness, or
  `winvm ssh`) instead.
- **The guest has no VRAM of its own.** The APU splits system memory, which is
  why it gets 16 GiB while the host keeps the rest.
- **The installation medium persists.** It holds the answer file (so, the
  admin password) and the domain XML points at it; the directory is `0700` and
  qemu reads it as root. Deleting it means the guest will not start.
- `winvm gpu on|off` and `winvm display on|off` only work while the domain is shut
  off. `gpu on` is idempotent: it will not attach the device twice.
- The emulated `cirrus`/`virtio` adapter is marked `primary`, so an application may
  render there even once the passed GPU works. `winvm display off` is the way to
  force a single adapter — but see above about it being a deliberate step.
- The guest agent needs a channel in the domain XML; `install` adds
  `org.qemu.guest_agent.0`. A domain created before that exists needs
  `virt-xml win --add-device --channel unix,target.type=virtio,target.name=org.qemu.guest_agent.0`
  (with the domain shut off) before `virsh domifaddr --source agent` works. It is
  a convenience only: `winvm status` falls back to the DHCP lease for the address.
- **The first boot needs a keypress.** The Windows media asks "press any key to
  boot from CD or DVD" and falls through to "no bootable device" if nobody
  answers, so `winvm install` sends keys for the first few seconds. Later boots
  rely on that prompt timing out (that is what stops a reinstall loop), so do not
  press keys again -- once Setup's UI is up, any key lands on its Cancel button.
