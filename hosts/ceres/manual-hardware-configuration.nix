{ config, lib, pkgs, modulesPath, mylib, ... }:

let
  subvol = mylib.btrfsSubvolOn "/dev/disk/by-uuid/87f4ba11-cdc1-4e4c-9c71-a797448f4de4" [
    "noatime"
    "compress-force=zstd"
    "autodefrag"
  ];
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "usb_storage" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems = {
    "/" = subvol "@";
    "/nix" = subvol "@nix";
    "/var" = subvol "@var";
    "/var/log" = subvol "@var/log";
    "/var/cache" = subvol "@var/cache";
    "/home" = subvol "@home";
    "/boot" = {
      device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
      fsType = "ext4";
    };
  };

  swapDevices = [ ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}
