# winvm

Control surface for the Windows test guest on jupiter. Plain `virsh` underneath;
this exists so an agent can drive the VM with a handful of non-interactive
commands instead of remembering libvirt flags.

## Shape

- **No GPU passthrough.** Both host GPUs stay on `amdgpu`: the discrete card
  (`1002:7550`, IOMMU group 14) for niri, Steam/Proton and LACT, the APU's iGPU
  (`1002:13c0`, group 28) unused. The guest gets libvirt's emulated `virtio-vga`
  and a VNC display on `127.0.0.1:5900`.
- **Two ways in.** `winvm console` for a human at a window, `winvm ssh` /
  `winvm ps` for anything automated. RDP is enabled for a desktop, but ssh is the
  interface the tests use.
- **An APU iGPU cannot be passed to a guest.** That was the first attempt: the
  device binds to `vfio-pci` fine and Windows sees it, but the AMD driver always
  returns code 43, because an APU's driver needs platform-firmware state (IGD
  opregion, UMA carve-out) that only the host firmware provides. A real PCIe card
  would work; the iGPU does not. Nothing in this module depends on it now.
- **No acceleration.** `virtio-vga` is a framebuffer, not a GPU: fine for driving
  the desktop and ordinary applications, useless for GPU-accelerated rendering.

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
winvm console                         # optional: watch it
```

`install` generates `~/.local/state/winvm/id_ed25519` (override with
`WINVM_MEDIA_DIR`), writes the answer file and first-logon script next to it,
bundles those with the VirtIO drivers into one medium, and starts the install.
Nothing to click: the edition comes from `WINVM_IMAGE_NAME` (default
`Windows 11 Pro`, chosen with the generic install key, so it is unactivated), the
disk is wiped and partitioned, and at first logon `winvm-bootstrap.ps1` enables
OpenSSH with that key, enables RDP, installs the guest agent, and writes the
adapter inventory to `C:\winvm-adapters.txt`.

After that the guest is reachable and there is nothing left to set up:

```sh
winvm status                          # state + address
winvm ssh -- cmd /c ver
```

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
policies. `-SkipExplorerRestart` is set, so most changes land at the next sign-in.

## Per-test state

```sh
winvm down && winvm snapshot base    # once, after the guest is set up and clean
winvm reset                          # destroy -> revert to base -> start
```

Snapshots are taken with the domain shut off, so `reset` always does a full boot.
That is the point: each test starts from the same disk. `winvm save` / `winvm
unsave` suspend and resume a running guest to `~/.local/state/winvm/save/`, for
keeping state across a host reboot.

## Acceptance test (do this before trusting the guest)

```sh
for i in $(seq 1 10); do
  winvm reset
  winvm ssh -- cmd /c echo booted $i
done
```

Ten clean boots from the same snapshot with the address coming back each time. If
`reset` is flaky, that loop is how you find out.

## Caveats

- **Don't measure graphics performance here.** There is no GPU: `virtio-vga`
  renders in software on the host CPU. Fine for a test harness that needs a
  desktop; not representative of real hardware.
- **The guest has no VRAM of its own.** It gets 16 GiB of system memory because
  it is a VM, not because a GPU is carving any out.
- **The installation medium persists.** It holds the answer file (so, the
  admin password) and the domain XML points at it; the directory is `0700` and
  qemu reads it as root. Deleting it means the guest will not start.
- `winvm snapshot` needs the domain shut off. `winvm reset` handles that itself.
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
