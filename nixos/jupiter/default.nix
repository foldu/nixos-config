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

  networking.firewall.allowedTCPPorts = [ config.services.hardware.openrgb.server.port
    # harmonia
    5000
  ];

  users.users.barnabas.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOD4usy2QkPC6J7YLNW9kSm5ZZdS11j2Ad3qipzhpUy/ jupiter.home.5kw.li"
  ];

  services.nix-cache-beacon = {
    # Announce cache to the local network
    advert = {
      enable = true;
      port = 5000; # Harmonia port
    };

    # Enable local binary cache using discovered caches on the local network
    cache.enable = true;
  };

  # Local binary cache using Harmonia
  # nix-cache-beacon can be used with any cache implementation
  services.harmonia.cache.enable = true; # Serve up local Nix store
  services.harmonia.signKeyPaths = ["/var/secrets/cashewnix-private"];

  environment.sessionVariables = {
    # auto upgrade fsr games to fsr4
    PROTON_FSR4_UPGRADE = "1";
  };
  system.stateVersion = "23.05"; # Did you read the comment?
  # no
}
