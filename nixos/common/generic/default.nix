{
  pkgs,
  lib,
  inputs,
  config,
  outputs,
  ...
}:
{
  imports = [
    ./cachix
    ./secrets.nix
    ./ssh.nix
    ./telegraf.nix
  ];

  hardware.enableRedistributableFirmware = true;

  # FIXME: should be in home-manager, but it currently doesn't support wayland sessions
  environment.sessionVariables = {
    EDITOR = "nvim";
    NIX_GCC = "${pkgs.gcc}/bin/gcc";
  };

  environment.systemPackages =
    [
      inputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim
      inputs.home-manager.packages.${pkgs.system}.home-manager
    ]
    ++ (with pkgs; [
      vopono
      wget
      curl
      jq
      fd
      ripgrep
      file
      helix
    ]);

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 14d";
    flake = "/home/barnabas/src/github.com/foldu/nixos-config";
  };

  nix = {
    # package = pkgs.nixVersions.latest;
    package = pkgs.lix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      trusted-public-keys = [ "jupiter:2laywrj8EfgDWW8GnDkIPuONvzMyrIirdAPWkvSIU0g=" ];
    };
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
  };

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
    };
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "de_DE.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
    ];
  };

  time.timeZone = "Europe/Amsterdam";

  users.users.barnabas = {
    isNormalUser = true;
    uid = 1000;
    shell = pkgs.nushell;
    extraGroups = [
      "wheel"
      "video"
      "audio"
      "dialout"
      "networkmanager"
    ];
    # FIXME: too lazy
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJQ+TsvKvdWG+9KLVeg5N4y1Ce1jr/fP3ELTHVWLxZOR"
    ];
  };

  boot.tmp.useTmpfs = true;

  networking.firewall.enable = true;

  # increase fd limits because they're way too low
  security.pam.loginLimits = [
    {
      domain = "*";
      item = "nofile";
      type = "soft";
      value = "65536";
    }
    {
      domain = "*";
      item = "nofile";
      type = "hard";
      value = "524288";
    }
  ];

  security.pki.certificateFiles = [ ../../../home_ca.crt ];

  services.tailscale.enable = true;

  networking.wireguard.enable = true;

  services.udev.extraRules = ''
    # set scheduler for non-rotating disks
    ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*|nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="kyber"
    # set scheduler for rotating disks
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
  '';
}
