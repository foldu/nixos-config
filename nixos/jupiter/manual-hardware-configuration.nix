# modify this file!
{ config, lib, outputs, modulesPath, ... }:

let
  subvol = outputs.lib.btrfsSubvolOn "/dev/disk/by-uuid/b02cb89c-f1e8-4ae7-95a5-5735046e98c7" [
    "noatime"
    "compress-force=zstd"
    "autodefrag"
  ];
in
{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "uas" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = subvol "root";

  fileSystems."/swap" = subvol "swap";

  fileSystems."/nix" = subvol "nix";

  fileSystems."/home" = subvol "home";

  fileSystems."/var" = subvol "var";

  fileSystems."/var/log" = subvol "var/log";

  fileSystems."/var/cache" = subvol "var/cache";

  fileSystems."/home/barnabas" = subvol "home/barnabas";

  fileSystems."/home/barnabas/.cache" = subvol "home/barnabas/.cache";

  fileSystems."/efi" =
    {
      device = "/dev/disk/by-uuid/DA01-5928";
      fsType = "vfat";
    };

  swapDevices = [
    { device = "/swap/swapfile"; size = 16 * 1024; }
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  # networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp8s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp6s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
