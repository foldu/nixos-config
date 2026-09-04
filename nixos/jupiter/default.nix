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
    ../common/cashewnix-cache.nix

    ./manual-hardware-configuration.nix
    ../common/graphical/amd-gpu.nix
    ./llama.nix
  ];

  nix.gc.automatic = lib.mkForce false;

  networking.hostName = "jupiter";

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;

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

  nix.settings.secret-key-files = [ config.sops.secrets."jupiter/binary-cache-secret-key".path ];

  sops.secrets."jupiter/binary-cache-secret-key" = { };

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # let nix schedule aarch64 builds under binfmt emulation
  nix.settings.extra-platforms = [ "aarch64-linux" ];

  services.hardware.openrgb = {
    enable = true;
    package = pkgs.openrgb-with-all-plugins;
    motherboard = "amd";
  };

  networking.firewall.allowedTCPPorts = [
    config.services.hardware.openrgb.server.port
  ];

  users.users.barnabas.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOD4usy2QkPC6J7YLNW9kSm5ZZdS11j2Ad3qipzhpUy/ jupiter.home.5kw.li"
  ];

  # hassctl (netbird-gw) poweroff access — dedicated user, see
  # packages/hassctl/README.md. The key can only run `sudo poweroff`
  # (forced command + restrict). Paste the public key below.
  #
  # The sudo rule targets a stable-path wrapper (/etc/hassctl/poweroff).
  # sudo-rs canonicalizes command paths by resolving *directory* symlinks
  # but never the command itself (see its src/common/resolve.rs), so a
  # forced command via /run/current-system/sw/bin/poweroff would
  # canonicalize to an unstable system-path store path that a store-path
  # rule never matches (and the rule's own hash churns on rebuilds).
  # With the /etc wrapper both the sudoers rule and the forced command
  # canonicalize to the same current store path on every rebuild.
  environment.etc."hassctl/poweroff".source = pkgs.writeShellScript "hassctl-poweroff" ''
    exec ${pkgs.systemd}/bin/poweroff
  '';

  users.users.powerctl = {
    isSystemUser = true;
    group = "powerctl";
    shell = pkgs.bash; # forced commands run via $SHELL -c; nologin would reject them
    extraGroups = [ "wheel" ]; # sudo-rs execWheelOnly = true
    openssh.authorizedKeys.keys = [
      "command=\"/run/wrappers/bin/sudo /etc/hassctl/poweroff\",restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGlajkEqswqSxvleHVtZEFOv9OTCInqHpRch43/iL6LV"
    ];
  };

  users.groups.powerctl = { };

  security.sudo-rs.extraRules = [
    {
      users = [ "powerctl" ];
      commands = [
        {
          command = "/etc/hassctl/poweroff";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  environment.sessionVariables = {
    # auto upgrade fsr games to fsr4
    PROTON_FSR4_UPGRADE = "1";
  };
  system.stateVersion = "23.05"; # Did you read the comment?
  # no
}
