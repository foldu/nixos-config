{
  pkgs,
  ...
}:
{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      # host-arch emulation only; plain qemu duplicates every TCG target
      package = pkgs.qemu_kvm;
      # Windows 11 refuses to install without a TPM 2.0
      swtpm.enable = true;
    };
  };

  # libvirtd's own polkit rule grants org.libvirt.unix.manage to members of the
  # `libvirtd` group -- the module references it but never creates it, and an
  # agent has no polkit agent to answer an interactive prompt. Membership is
  # root-equivalent: libvirt can attach any host device to a guest.
  users.groups.libvirtd = { };
  users.users.barnabas.extraGroups = [ "libvirtd" ];

  # virt-manager also brings virt-install and virt-xml, which winvm drives
  programs.virt-manager.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;

  # libvirt ships an ssh_config.d snippet (its ssh proxy for `qemu+ssh://`) that
  # the module wires into programs.ssh.extraConfig. It lives in the store, so it
  # is owned by nobody/nogroup and OpenSSH rejects it -- "Bad owner or
  # permissions" -- which breaks every ssh invocation on the host, including
  # git and `just deploy`. We do not use qemu+ssh, so drop it.
  virtualisation.libvirtd.sshProxy = false;

  environment.systemPackages = with pkgs; [
    virtio-win # extracted driver tree, served to guests as a read-only cdrom
    qemu-utils # qemu-img, for overlays and offline inspection
    freerdp # `xfreerdp /v:192.168.122.50` for a human
  ];
}
