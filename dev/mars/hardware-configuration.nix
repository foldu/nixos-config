# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, inputs, ... }:

{
  imports =
    [
      "${inputs.nixpkgs}/nixos/modules/installer/scan/not-detected.nix"
    ];

  boot.initrd.availableKernelModules = [ "nvme" "ehci_pci" "xhci_pci" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/de4e230c-5ce6-4334-8bef-f129b4c40707";
      fsType = "xfs";
    };

  fileSystems."/home" =
    {
      device = "/dev/disk/by-uuid/e0e571db-ff05-4498-8210-4543e1fa53f6";
      fsType = "xfs";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/CE21-B21C";
      fsType = "vfat";
    };

  swapDevices =
    [
      { device = "/dev/disk/by-uuid/30ff234d-37eb-4eaf-974a-be77e756537c"; }
    ];

  nix.maxJobs = lib.mkDefault 16;
}
