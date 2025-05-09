{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-pc-ssd

    ../common/profiles/desktop.nix

    ../common/bluetooth.nix
    ../common/butter.nix
    ../common/graphical
    ../common/cashewnix-cache.nix
    ../common/gitlab-runner.nix

    ./manual-hardware-configuration.nix
    ./docker.nix
    ./ollama.nix
  ];

  programs.nix-ld.enable = true;

  nix.gc.automatic = lib.mkForce false;

  networking.hostName = "jupiter";

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
      useOSProber = true;
    };
  };

  environment.sessionVariables = {
    MAKEFLAGS = "-j 32";
  };

  nix.settings.secret-key-files = [ "/var/secrets/jupiter.priv" ];

  zramSwap.enable = true;

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  system.stateVersion = "23.05"; # Did you read the comment?
  # no
}
