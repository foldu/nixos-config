{ config, lib, pkgs, ... }: {
  imports = [
    ../../roles/amd-gpu.nix
    ../../roles/bluetooth.nix
    ../../roles/desktop.nix
    ../../roles/graphical.nix
    ../../roles/home.nix
    ../../roles/x86.nix
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
