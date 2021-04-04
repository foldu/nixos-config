{ config, lib, pkgs, ... }: {
  imports = [
    ../../profiles/amd-gpu.nix
    ../../profiles/bluetooth.nix
    ../../profiles/desktop.nix
    ../../profiles/graphical
    ../../profiles/home.nix
    ../../profiles/x86.nix
    ./hardware-configuration.nix
  ];

  boot.loader = {
    systemd-boot = {
      enable = true;
      editor = false;
    };
    efi.canTouchEfiVariables = true;
  };

  system.stateVersion = "20.09";
}
