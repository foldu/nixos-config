# modify this file!
{ lib, modulesPath, outputs, ... }:

let
  subvol = outputs.lib.btrfsSubvolOn "/dev/disk/by-uuid/eec24fdd-613a-45f5-8749-0057b3b89ffc" [
    "noatime"
    "compress-force=zstd"
    "autodefrag"
  ];
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "nvme" "ehci_pci" "xhci_pci" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems = {
    "/" = subvol "@";
    "/nix" = subvol "@nix";
    "/var" = subvol "@var";
    "/var/log" = subvol "@var/log";
    "/var/cache" = subvol "@var/cache";
    "/home" = subvol "@home";
    "/boot/efi" = {
      device = "/dev/disk/by-uuid/8796-8505";
      fsType = "vfat";
    };
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/254ea229-e97c-46e4-9cdf-ba56f1d98ad6"; }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
