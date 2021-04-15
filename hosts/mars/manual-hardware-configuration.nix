# modify this file!
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "nvme" "ehci_pci" "xhci_pci" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/eec24fdd-613a-45f5-8749-0057b3b89ffc";
    fsType = "btrfs";
    options = [ "subvol=@" "autodefrag" "noatime" "compress-force=zstd" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/eec24fdd-613a-45f5-8749-0057b3b89ffc";
    fsType = "btrfs";
    options = [ "subvol=@nix" "autodefrag" "noatime" "compress-force=zstd" ];
  };

  fileSystems."/var" = {
    device = "/dev/disk/by-uuid/eec24fdd-613a-45f5-8749-0057b3b89ffc";
    fsType = "btrfs";
    options = [ "subvol=@var" "autodefrag" "noatime" "compress-force=zstd" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/eec24fdd-613a-45f5-8749-0057b3b89ffc";
    fsType = "btrfs";
    options = [ "subvol=@home" "autodefrag" "noatime" "compress-force=zstd" ];
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/8796-8505";
    fsType = "vfat";
  };

  fileSystems."/var/cache" = {
    device = "/dev/disk/by-uuid/eec24fdd-613a-45f5-8749-0057b3b89ffc";
    fsType = "btrfs";
    options = [ "subvol=@var/cache" "autodefrag" "noatime" "compress-force=zstd" ];
  };

  fileSystems."/var/log" = {
    device = "/dev/disk/by-uuid/eec24fdd-613a-45f5-8749-0057b3b89ffc";
    fsType = "btrfs";
    options = [ "subvol=@var/log" "autodefrag" "noatime" "compress-force=zstd" ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/254ea229-e97c-46e4-9cdf-ba56f1d98ad6"; }
  ];

}
