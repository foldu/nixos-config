{ config, pkgs, lib, ... }: {
  imports = [
    ../../profiles/amd-gpu.nix
    ../../profiles/bluetooth.nix
    ../../profiles/graphical
    ../../profiles/home.nix
    ../../profiles/laptop.nix
    ../../profiles/x86.nix
    ./manual-hardware-configuration.nix
  ];

  nix.distributedBuilds = true;

  # uefi suxxxxx
  boot.loader = {
    efi = {
      #canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
    grub = {
      enable = true;
      device = "nodev";
      efiInstallAsRemovable = true;
      efiSupport = true;
    };
  };

  # FIXME: linux 5.14 has even worse ACPI issues than 5.10
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_5_10;

  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/" ];
  };

  system.stateVersion = "20.09";
}
