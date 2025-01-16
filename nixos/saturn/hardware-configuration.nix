# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "rpool/system/root";
    fsType = "zfs";
  };

  fileSystems."/nix" = {
    device = "rpool/local/nix";
    fsType = "zfs";
  };

  fileSystems."/var" = {
    device = "rpool/system/var";
    fsType = "zfs";
  };

  fileSystems."/var/postgres" = {
    device = "rpool/system/postgres";
    fsType = "zfs";
  };

  fileSystems."/home" = {
    device = "rpool/user";
    fsType = "zfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/2664640c-30c5-48c2-8610-dda048ace8bd";
    fsType = "ext4";
  };

  fileSystems."/srv/media/main" = {
    device = "main";
    fsType = "zfs";
  };

  fileSystems."/srv/media/cia/data" = {
    device = "cia/data";
    fsType = "zfs";
  };

  fileSystems."/srv/media/cia/cache" = {
    device = "cia/cache";
    fsType = "zfs";
  };

  fileSystems."/srv/media/nvme1/data" = {
    device = "nvme1/data";
    fsType = "zfs";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/6963baa8-8979-4cd1-b740-7a06900a7b03"; } ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
