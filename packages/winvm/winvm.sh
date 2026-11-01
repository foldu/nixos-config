#!/usr/bin/env bash
# Agent-facing control surface for the Windows guest on jupiter.
# Everything here is one non-interactive command; see README.md.
set -euo pipefail

# a non-root virsh defaults to qemu:///session, which is a different daemon with
# no guest in it; every command here means the system one
export LIBVIRT_DEFAULT_URI="qemu:///system"
export VIRSH_DEFAULT_CONNECT_URI="qemu:///system"

domain="@domain@"
ip="@ip@"
mac="@mac@"
hostdev="@hostdev@"
guest_user="@user@"
hostname="@hostname@"
timezone="@timezone@"
drivers="@drivers@"
answer_file="@answer_file@"
bootstrap_ps1="@bootstrap_ps1@"
debloat_dir="@debloat@"
# media and key live in user state: /var/lib/libvirt is root-owned, and qemu runs
# as root so it can read these anyway. The directory has to persist -- the domain
# XML points at the installation medium, and losing it means the guest will not
# start.
media_dir="${WINVM_MEDIA_DIR:-${XDG_STATE_HOME:-$HOME/.local/share}/winvm}"
state_dir="$media_dir/save"
shutdown_timeout="${WINVM_SHUTDOWN_TIMEOUT:-60}"

# pci address as libvirt spells it (0000:75:00.0 -> bus 0x75, slot 0x00, function 0x0)
bdf="${hostdev#*:}"
pci_bus="0x${bdf%%:*}"
rest="${bdf#*:}"
pci_slot="0x${rest%%.*}"
pci_func="${rest#*.}"

die() { printf 'winvm: %s\n' "$*" >&2; exit 1; }

has_domain() { virsh dominfo "$domain" >/dev/null 2>&1; }

is_running() { [ "$(virsh domstate "$domain" 2>/dev/null || true)" = "running" ]; }

# The DHCP reservation is the stable answer, but it only applies once the network
# has been redefined from this repo's XML; until then (and for any guest the file
# owner changed under), fall back to what the guest actually got.
guest_ip() {
  local addr=""
  if is_running; then
    addr="$(virsh domifaddr "$domain" --source agent 2>/dev/null |
      awk '$3 == "ipv4" { print $4; exit }' | cut -d/ -f1)"
    if [ -z "$addr" ]; then
      addr="$(virsh net-dhcp-leases default 2>/dev/null |
        awk -v mac="$mac" '$3 == mac { print $5; exit }' | cut -d/ -f1)"
    fi
  fi
  printf '%s' "${addr:-$ip}"
}

xml_escape() {
  local s=$1
  s=${s//&/\&amp;}
  s=${s//</\&lt;}
  s=${s//>/\&gt;}
  s=${s//\"/\&quot;}
  printf '%s' "$s"
}

# ${var//pat/rep} treats & and \ specially in rep, which matters here: driver
# paths are full of backslashes and a password may well contain &.
subst() {
  local haystack=$1 needle=$2 value=$3
  value=${value//\\/\\\\}
  value=${value//&/\\&}
  printf '%s' "${haystack//"$needle"/$value}"
}

usage() {
  cat <<EOF
usage: winvm <command>

lifecycle
  status [--json]     domain state, guest address, whether the GPU is attached
  up                  start the domain
  down [-f]           ACPI shutdown, destroy after ${shutdown_timeout}s (-f: hard stop)

test state
  snapshot [name]     disk snapshot while shut off (default: base)
  restore [name]      revert the disk to a snapshot (default: base)
  reset               destroy -> revert to base -> start   <- the test primitive
  save [name]         suspend the running domain to ${state_dir}/<name>.state
  unsave [name]       resume from that save file

access
  ssh [cmd ...]       run a command in the guest over OpenSSH (winvm's own key)
  console             virt-viewer (only while the virtual display is attached)
  ps 'script'         run PowerShell in the guest, quoting-proof
  key KEYNAME...      inject keys into the guest, e.g. KEY_ENTER

setup
  install             one-shot unattended Windows install
                      (WINVM_ISO and WINVM_PASSWORD required;
                       WINVM_IMAGE_NAME picks the edition, WINVM_ATTENDED=1 goes manual)
  gpu on|off          attach/detach the passed-through iGPU
  display on|off      emulated display (off = single adapter, guest must drive the GPU)
  debloat [--dry-run] run the vendored Win11Debloat against the live guest
  bootstrap           re-print the first-logon script, with the key filled in
EOF
}

cmd_status() {
  local state=undefined gpu=no addr
  addr="$(guest_ip)"
  if has_domain; then
    state="$(virsh domstate "$domain")"
    if virsh dumpxml "$domain" |
      grep -q "bus='$pci_bus' slot='$pci_slot' function='0x$pci_func'"; then
      gpu=yes
    fi
  fi
  if [ "${1:-}" = "--json" ]; then
    printf '{"domain":"%s","state":"%s","ip":"%s","gpu":%s}\n' \
      "$domain" "$state" "$addr" "$([ "$gpu" = yes ] && echo true || echo false)"
  else
    printf 'domain   %s\nstate    %s\naddress  ssh %s@%s\ngpu      %s\n' \
      "$domain" "$state" "$guest_user" "$addr" "$gpu"
  fi
}

cmd_up() {
  has_domain || die "domain $domain is not defined yet (winvm install)"
  if is_running; then
    echo "already running"
    return 0
  fi
  virsh start "$domain" >/dev/null
  echo "started $domain"
}

cmd_down() {
  if ! is_running; then
    echo "already off"
    return 0
  fi
  case ${1:-} in
  -f | --force)
    virsh destroy "$domain" >/dev/null
    echo "destroyed"
    return 0
    ;;
  esac
  virsh shutdown "$domain" >/dev/null
  local _ waited=0
  for _ in $(seq 1 "$shutdown_timeout"); do
    if ! is_running; then
      echo "shut down"
      return 0
    fi
    sleep 1
    waited=$((waited + 1))
  done
  echo "ACPI shutdown timed out after ${waited}s, destroying"
  virsh destroy "$domain" >/dev/null
}

cmd_snapshot() {
  local name="${1:-base}"
  # a domain with a passed-through device cannot be snapshotted live
  is_running && die "shut the domain down first (winvm down) -- hostdev blocks live snapshots"
  virsh snapshot-create-as "$domain" "$name" --description "winvm $name" --atomic
}

cmd_restore() {
  local name="${1:-base}"
  has_domain || die "domain $domain is not defined"
  is_running && virsh destroy "$domain" >/dev/null
  virsh snapshot-revert "$domain" "$name"
}

cmd_reset() {
  has_domain || die "domain $domain is not defined"
  is_running && virsh destroy "$domain" >/dev/null
  if virsh snapshot-info "$domain" base >/dev/null 2>&1; then
    virsh snapshot-revert "$domain" base
  else
    echo "no 'base' snapshot; booting the disk as it is" >&2
  fi
  virsh start "$domain" >/dev/null
  echo "reset to base and started"
}

cmd_save() {
  local name="${1:-base}"
  is_running || die "domain is not running"
  install -d -m 0700 "$state_dir"
  virsh save "$domain" "$state_dir/$name.state"
}

cmd_unsave() {
  local file="$state_dir/${1:-base}.state"
  [ -f "$file" ] || die "no saved state at $file"
  virsh restore "$file"
}

# -F /dev/null: ignore any system ssh_config (libvirt's own snippet broke that
# once). Everything after the destination is the remote command.
guest_ssh() {
  ssh -F /dev/null -i "$media_dir/id_ed25519" \
    -o BatchMode=yes \
    -o IdentitiesOnly=yes \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR \
    -o ConnectTimeout=10 \
    "$guest_user@$(guest_ip)" "$@"
}

# Windows sshd reassembles the remote command line, so quotes and metacharacters
# turn into a quoting argument. -EncodedCommand takes base64 of UTF-16LE instead.
ps_encoded() {
  # progress records come back as CLIXML noise over ssh, so turn them off
  local script="\$ProgressPreference='SilentlyContinue'; $1"
  printf 'powershell -NoProfile -NonInteractive -EncodedCommand %s' \
    "$(printf '%s' "$script" | iconv -f UTF-8 -t UTF-16LE | base64 -w0)"
}

cmd_ssh() {
  if [ "${1:-}" = "--" ]; then shift; fi
  [ $# -gt 0 ] || die "usage: winvm ssh COMMAND..."
  guest_ssh "$@"
}

# Windows sshd reassembles the remote command line, so anything with quotes or
# metacharacters turns into a quoting argument. -EncodedCommand takes base64 of
# UTF-16LE instead and sidesteps it completely.
cmd_ps() {
  [ $# -gt 0 ] || die "usage: winvm ps 'powershell script'"
  guest_ssh "$(ps_encoded "$*")"
}

cmd_key() {
  [ $# -gt 0 ] || die "usage: winvm key KEYNAME [KEYNAME...]  (e.g. KEY_ENTER, KEY_SPACE)"
  virsh send-key "$domain" "$@"
}

cmd_console() {
  has_domain || die "domain $domain is not defined"
  if ! virsh dumpxml "$domain" | grep -q "<graphics"; then
    die "no emulated display to show -- the iGPU is the guest's display now; run 'winvm gpu off' for a console"
  fi
  exec virt-viewer --connect qemu:///system --wait "$domain"
}

cmd_gpu() {
  has_domain || die "domain $domain is not defined"
  is_running && die "shut the domain down first (winvm down)"
  case ${1:-} in
  on)
    if virsh dumpxml "$domain" | grep -q "bus='$pci_bus' slot='$pci_slot' function='0x$pci_func'"; then
      echo "iGPU $hostdev already attached"
    else
      virt-xml "$domain" --add-device --hostdev "$hostdev" >/dev/null
      echo "iGPU $hostdev attached"
    fi
    ;;
  off)
    if ! virsh dumpxml "$domain" | grep -q "bus='$pci_bus' slot='$pci_slot' function='0x$pci_func'"; then
      echo "iGPU $hostdev already detached"
    else
      virt-xml "$domain" --remove-device --hostdev "$hostdev" >/dev/null
      echo "iGPU $hostdev detached"
    fi
    ;;
  *)
    die "usage: winvm gpu on|off"
    ;;
  esac
}

# The emulated display is what makes the guest usable before its own GPU driver
# works. Turning it off leaves a single adapter (no ambiguity about which one an
# application renders on), but a guest with neither has been observed to never
# finish booting, so this is a separate, deliberate step.
cmd_display() {
  has_domain || die "domain $domain is not defined"
  is_running && die "shut the domain down first (winvm down)"
  case ${1:-} in
  off)
    virt-xml "$domain" --remove-device --graphics all >/dev/null 2>&1 || true
    virt-xml "$domain" --edit --video model.type=none >/dev/null
    echo "emulated display off; the guest must drive a passed-through GPU to be usable"
    ;;
  on)
    virt-xml "$domain" --edit --video model.type=virtio >/dev/null
    if ! virsh dumpxml "$domain" | grep -q "<graphics"; then
      virt-xml "$domain" --add-device --graphics vnc,listen=127.0.0.1 >/dev/null
    fi
    echo "emulated display on"
    ;;
  *)
    die "usage: winvm display on|off"
    ;;
  esac
}

# The flags are deliberately conservative: no Edge removal, no Defender or
# Windows Update changes, nothing that renames services. Enough to stop the
# telemetry/ads/nudges and the app noise, not enough to make the guest
# unrepresentative of Windows.
debloat_flags() {
  printf '%s' "-Silent -SkipExplorerRestart -RemoveApps -DisableTelemetry -DisableBing -DisableSuggestions -DisableWidgets -DisableLockscreenTips -DisableSettings365Ads -DisableCopilot -DisableRecall -DisableClickToDo -DisableAISvcAutoStart -DisableDeviceAutoAppDownload -DisableDeliveryOptimization -DisableFastStartup"
}

debloat_block() {
  local flags
  flags="$(debloat_flags)"
  # shellcheck disable=SC2016  # $medium is PowerShell, not bash
  printf '%s\n' \
    '$medium = (Get-CimInstance Win32_CDROMDrive | Where-Object VolumeName -like "*WINVM*").DriveLetter' \
    'if ($medium -and (Test-Path "${medium}:\win11debloat\Win11Debloat.ps1")) {' \
    "  & \"\${medium}:\\win11debloat\\Win11Debloat.ps1\" $flags *> C:\winvm-debloat.log" \
    '}'
}

render_bootstrap() {
  local key=$1 script block
  script="$(cat "$bootstrap_ps1")"
  script="$(subst "$script" "@@SSH_KEY@@" "$key")"
  if [ "${WINVM_DEBLOAT:-1}" = 0 ]; then
    block="# Win11Debloat not requested for this install."
  else
    block="$(debloat_block)"
  fi
  subst "$script" "@@DEBLOAT@@" "$block"
  printf '\n'
}

# The installation medium: VirtIO drivers for Setup, the first-logon script, and
# -- unless the run is attended -- the answer file that never runs OOBE and
# creates a local administrator instead of a Microsoft account.
build_media() {
  install -d -m 0700 "$media_dir"
  if [ ! -f "$media_dir/id_ed25519" ]; then
    ssh-keygen -q -t ed25519 -N "" -C "winvm@$hostname" -f "$media_dir/id_ed25519"
    echo "generated $media_dir/id_ed25519" >&2
  fi
  local pubkey
  pubkey="$(cat "$media_dir/id_ed25519.pub")"

  local stage
  stage="$(mktemp -d)"
  cp -r "$drivers"/. "$stage/"

  render_bootstrap "$pubkey" >"$stage/winvm-bootstrap.ps1"

  # shipped whenever the guest might want it, run by the bootstrap
  cp -r "$debloat_dir" "$stage/win11debloat"

  if [ "${1:-unattended}" = unattended ]; then
    [ -n "${WINVM_PASSWORD:-}" ] || die "set WINVM_PASSWORD for the local admin account"

    # Windows Setup assigns drive letters to attached media in no particular
    # order, and a driver path that does not exist is skipped, so cover the
    # plausible letters.
    local paths="" letter drv n=0
    for letter in D E F G; do
      for drv in viostor vioscsi NetKVM; do
        n=$((n + 1))
        paths+="        <PathAndCredentials wcm:action=\"add\" wcm:keyValue=\"$n\">
          <Path>$letter:\\$drv\\w11\\amd64</Path>
        </PathAndCredentials>
"
      done
    done

    local xml
    xml="$(cat "$answer_file")"
    xml="$(subst "$xml" "@@DRIVER_PATHS@@" "$paths")"
    xml="$(subst "$xml" "@@USER@@" "$guest_user")"
    xml="$(subst "$xml" "@@PASSWORD@@" "$(xml_escape "$WINVM_PASSWORD")")"
    xml="$(subst "$xml" "@@HOSTNAME@@" "$hostname")"
    xml="$(subst "$xml" "@@TIMEZONE@@" "$timezone")"
    xml="$(subst "$xml" "@@IMAGE_NAME@@" "${WINVM_IMAGE_NAME:-Windows 11 Pro}")"
    printf '%s\n' "$xml" >"$stage/autounattend.xml"
  else
    echo "attended install: Setup will ask for the edition and show no disks." >&2
    echo "use 'Load driver' and pick the virtio-win medium for the storage driver." >&2
  fi

  # the store copies are read-only, and their directories are not writable
  # either, which makes the temp stage undeletable
  chmod -R u+w "$stage"
  xorriso -as mkisofs -quiet -J -R -V WINVM -o "$media_dir/install.iso" "$stage"
  rm -rf "$stage"
}

cmd_install() {
  has_domain && die "domain $domain already exists"
  [ -n "${WINVM_ISO:-}" ] || die "set WINVM_ISO to a Windows installation ISO"
  [ -r "$WINVM_ISO" ] || die "cannot read $WINVM_ISO"

  local mode=unattended
  if [ "${WINVM_ATTENDED:-0}" = 1 ]; then
    mode=attended
  fi
  build_media "$mode"

  virt-install --connect qemu:///system \
    --name "$domain" \
    --osinfo win11 \
    --machine q35 \
    --cpu host-passthrough \
    --memory 16384 \
    --vcpus 12 \
    --disk "/var/lib/libvirt/images/$domain.qcow2,size=64,format=qcow2,bus=virtio,cache=writeback,discard=unmap" \
    --cdrom "$WINVM_ISO" \
    --disk "$media_dir/install.iso,device=cdrom,readonly=on" \
    --network "network=default,mac=$mac,model=virtio" \
    --channel unix,target.type=virtio,target.name=org.qemu.guest_agent.0 \
    --tpm backend.type=emulator,backend.version=2.0,model=tpm-crb \
    --graphics vnc,listen=127.0.0.1 \
    --video virtio \
    --boot uefi \
    --noautoconsole

  # The Windows media asks "press any key to boot from CD or DVD" and falls
  # through to "no bootable device" if nobody answers -- nothing else presses it.
  # Send keys for a few seconds only: once Setup's UI is up the same keys land on
  # its Cancel button, and one of them will take the "are you sure you want to
  # quit?" default.
  local _ keys="${WINVM_BOOT_KEYS:-8}"
  for _ in $(seq 1 "$keys"); do
    virsh send-key "$domain" KEY_SPACE >/dev/null 2>&1 || true
    sleep 1
  done

  echo "install started; watch it with: winvm console"
  echo "answer file, first-logon script and key live in $media_dir"
}

# Run the vendored Win11Debloat against a guest that is already installed, for
# the case where the box predates it or the settings were not wanted at install
# time. --dry-run passes -WhatIf, which prints the intended changes and applies
# none of them.
cmd_debloat() {
  is_running || die "the guest is not running (winvm up)"
  local extra="" remote='C:\ProgramData\win11debloat'
  case ${1:-} in
  "") ;;
  --dry-run) extra="-WhatIf" ;;
  *) die "usage: winvm debloat [--dry-run]" ;;
  esac

  guest_ssh "$(ps_encoded "New-Item -ItemType Directory -Force $remote | Out-Null")"
  tar -C "$debloat_dir" -cf - . | guest_ssh "tar -C $remote -xf -"
  guest_ssh "powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $remote\Win11Debloat.ps1 $(debloat_flags) $extra"
}

cmd_bootstrap() {
  [ -f "$media_dir/id_ed25519.pub" ] ||
    die "no key yet in $media_dir -- run winvm install first"
  render_bootstrap "$(cat "$media_dir/id_ed25519.pub")"
}

case ${1:-} in
status) shift && cmd_status "$@" ;;
up) cmd_up ;;
down) shift && cmd_down "$@" ;;
snapshot) shift && cmd_snapshot "$@" ;;
restore) shift && cmd_restore "$@" ;;
reset) cmd_reset ;;
save) shift && cmd_save "$@" ;;
unsave) shift && cmd_unsave "$@" ;;
ssh) shift && cmd_ssh "$@" ;;
console) cmd_console ;;
ps) shift && cmd_ps "$@" ;;
key) shift && cmd_key "$@" ;;
gpu) shift && cmd_gpu "$@" ;;
display) shift && cmd_display "$@" ;;
install) cmd_install ;;
debloat) shift && cmd_debloat "$@" ;;
bootstrap) cmd_bootstrap ;;
help | -h | --help | "") usage ;;
*) die "unknown command: $1 (see: winvm help)" ;;
esac
