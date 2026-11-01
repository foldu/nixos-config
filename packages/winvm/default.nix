{
  lib,
  fetchFromGitHub,
  gnutar,
  runCommand,
  writeShellApplication,
  coreutils,
  glibc,
  gnugrep,
  libvirt,
  openssh,
  qemu-utils,
  virt-manager,
  virt-viewer,
  virtio-win,
  xorriso,
  domain ? "win",
  ip ? "192.168.122.50",
  guestMac ? "52:54:00:9f:1a:6d",
  hostdev ? "0000:75:00.0",
  user ? "win",
  computerName ? "winvm",
  timezone ? "W. Europe Standard Time",
}:

let
  # Win11Debloat: pinned to a release and vendored, so a guest never depends on
  # a live URL (upstream's quick-start is `irm https://debloat.raphi.re/ | iex`).
  # Bump the tag and hash together.
  # (the release .zip stores backslash path separators and will not unpack, so
  # this is the source tree at the release tag)
  win11Debloat = fetchFromGitHub {
    owner = "Raphire";
    repo = "Win11Debloat";
    tag = "2026.10.30";
    hash = "sha256-1nyKVb3q3khN6BWAcijB2zoRIJ0fLFDd/psq0Nqm+kg=";
  };

  # Windows Setup only loads drivers from removable media, and the store copy of
  # virtio-win is an unpacked 836 MiB tree covering two decades of Windows. The
  # x64 drivers for the OSes this guest could plausibly be, plus the guest tools
  # MSI, are enough; `winvm install` puts this onto the installation medium.
  drivers = runCommand "virtio-win-drivers" { } ''
    mkdir -p $out
    for drv in ${virtio-win}/*/; do
      name=$(basename "$drv")
      for os in w11 w10; do
        if [ -d "$drv/$os/amd64" ]; then
          install -d "$out/$name/$os"
          cp -r "$drv/$os/amd64" "$out/$name/$os/"
        fi
      done
    done
    cp ${virtio-win}/virtio-win-gt-x64.msi ${virtio-win}/virtio-win_license.txt $out/
    # the gt MSI is drivers only -- the guest agent is its own package
    install -d "$out/guest-agent"
    cp ${virtio-win}/guest-agent/qemu-ga-x86_64.msi "$out/guest-agent/"
    if [ -d ${virtio-win}/cert ]; then cp -r ${virtio-win}/cert $out/; fi
    chmod -R u+w $out
  '';
in
writeShellApplication {
  name = "winvm";

  runtimeInputs = [
    (lib.getBin glibc)
    coreutils
    gnugrep
    gnutar
    libvirt
    openssh
    qemu-utils
    virt-manager
    virt-viewer
    xorriso
  ];

  text =
    lib.replaceStrings
      [
        "@domain@"
        "@ip@"
        "@mac@"
        "@hostdev@"
        "@user@"
        "@hostname@"
        "@timezone@"
        "@drivers@"
        "@answer_file@"
        "@bootstrap_ps1@"
        "@debloat@"
      ]
      [
        domain
        ip
        guestMac
        hostdev
        user
        computerName
        timezone
        "${drivers}"
        "${./autounattend.xml}"
        "${./bootstrap.ps1}"
        "${win11Debloat}"
      ]
      (builtins.readFile ./winvm.sh);

  meta = {
    description = "Start/stop/snapshot/reach the Windows test guest on jupiter (see README.md)";
    mainProgram = "winvm";
  };
}
