{
  inputs,
  config,
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
    ../common/graphical/amd-gpu.nix
    ./llama.nix
  ];

  programs.nix-ld.enable = true;

  nix.gc.automatic = lib.mkForce false;

  networking.hostName = "jupiter";

  boot.kernelPackages =
    lib.mkForce
      inputs.nix-cachyos-kernel.legacyPackages.${pkgs.stdenv.hostPlatform.system}.linuxPackages-cachyos-latest-lto-zen4;

  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/efi";
    };
    limine.enable = true;
  };

  environment.sessionVariables = {
    MAKEFLAGS = "-j 32";
  };

  nix.settings.secret-key-files = [ "/var/secrets/jupiter.priv" ];

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  services.hardware.openrgb = {
    enable = true;
    package = pkgs.openrgb-with-all-plugins;
    motherboard = "amd";
  };

  networking.firewall.allowedTCPPorts = [ config.services.hardware.openrgb.server.port ];

  users.users.barnabas.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOD4usy2QkPC6J7YLNW9kSm5ZZdS11j2Ad3qipzhpUy/ jupiter.home.5kw.li"
  ];

  environment.sessionVariables = {
    # auto upgrade fsr games to fsr4
    PROTON_FSR4_UPGRADE = "1";
  };
  system.stateVersion = "23.05"; # Did you read the comment?
  # no
}
