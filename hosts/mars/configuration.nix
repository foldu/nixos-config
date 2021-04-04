{ config, pkgs, lib, ... }: {
  imports = [
    ../../profiles/amd-gpu.nix
    ../../profiles/bluetooth.nix
    ../../profiles/graphical
    ../../profiles/home.nix
    ../../profiles/laptop.nix
    ../../profiles/x86.nix
    ./hardware-configuration.nix
  ];

  # TODO: fprintd

  boot.loader = {
    systemd-boot = {
      enable = true;
      editor = false;
    };
    efi.canTouchEfiVariables = true;
  };

  system.stateVersion = "20.09";
}
