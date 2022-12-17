{ config, lib, pkgs, inputs, ... }: {
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    ../../profiles/bluetooth.nix
    ../../profiles/desktop.nix
    ../../profiles/graphical
    ../../profiles/home
    ../../profiles/x86.nix
    ./manual-hardware-configuration.nix
    ../../profiles/builder.nix
    ../../profiles/butter.nix
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

  zramSwap.enable = true;

  system.stateVersion = "23.05"; # Did you read the comment?
  # no
}
