{ config, lib, pkgs, ... }: {
  imports = [
    ../../profiles/bluetooth.nix
    ../../profiles/desktop.nix
    ../../profiles/graphical
    ../../profiles/home
    ../../profiles/x86.nix
    ./manual-hardware-configuration.nix
    ../../profiles/builder.nix
  ];

  boot.loader = {
    efi = {
      #canTouchEfiVariables = true;
      efiSysMountPoint = "/efi";
    };
    grub = {
      enable = true;
      device = "nodev";
      efiInstallAsRemovable = true;
      efiSupport = true;
    };
  };

  environment.sessionVariables = {
    MAKEFLAGS = "-j 32";
  };

  virtualisation.docker.storageDriver = "btrfs";

  system.stateVersion = "23.05"; # Did you read the comment?
  # no
}
