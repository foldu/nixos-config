# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "thunderbolt"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/5db8bf35-5023-4d24-b7d3-0403952ac65d";
    fsType = "btrfs";
    options = [
      "subvol=root"
      "noatime"
      "compress=zstd"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/5db8bf35-5023-4d24-b7d3-0403952ac65d";
    fsType = "btrfs";
    options = [
      "subvol=home"
      "noatime"
      "compress=zstd"
    ];
  };

  fileSystems."/nix/store" = {
    device = "/dev/disk/by-uuid/5db8bf35-5023-4d24-b7d3-0403952ac65d";
    fsType = "btrfs";
    options = [
      "subvol=nix"
      "noatime"
      "compress=zstd"
    ];
  };

  fileSystems."/swap" = {
    device = "/dev/disk/by-uuid/5db8bf35-5023-4d24-b7d3-0403952ac65d";
    fsType = "btrfs";
    options = [
      "subvol=swap"
      "noatime"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/5254-4D3C";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };
  swapDevices = [ { device = "/swap/swapfile"; } ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp1s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
