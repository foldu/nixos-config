{ config, lib, pkgs, ... }: {
  imports = [
    ../../profiles/amd-gpu.nix
    ../../profiles/bluetooth.nix
    ../../profiles/desktop.nix
    ../../profiles/graphical
    ../../profiles/home
    ../../profiles/x86.nix
    ./hardware-configuration.nix
    ../../profiles/builder.nix
  ];

  boot.loader = {
    systemd-boot = {
      enable = true;
      editor = false;
    };
    efi.canTouchEfiVariables = true;
  };

  environment.sessionVariables = {
    MAKEFLAGS = "-j 32";
  };

  system.stateVersion = "20.09";
}
