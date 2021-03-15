{ config, pkgs, lib, ... }: {
  imports = [
    ../../roles/amd-gpu.nix
    ../../roles/bluetooth.nix
    ../../roles/graphical.nix
    ../../roles/home.nix
    ../../roles/laptop.nix
    ../../roles/x86.nix
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
