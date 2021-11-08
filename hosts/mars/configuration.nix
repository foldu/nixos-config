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


  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/" ];
  };

  environment.sessionVariables = {
    MAKEFLAGS = "-j 16";
  };

  system.stateVersion = "20.09";
}
