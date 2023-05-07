{ pkgs, lib, inputs, config, outputs, ... }: {
  imports = [
    ./cachix
    ./secrets.nix
    ./ssh.nix
  ];

  # FIXME: should be in home-manager, but it currently doesn't support wayland sessions
  environment.sessionVariables = {
    EDITOR = "nvim";
    NIX_GCC = "${pkgs.gcc}/bin/gcc";
  };

  environment.systemPackages = with pkgs; [
    inputs.home-manager.packages.${pkgs.system}.home-manager
    wget
    curl
    jq
    fd
    ripgrep
    file
    # gets overriden by home-manager on systems where I need an IDE
    (neovim.override {
      configure = {
        packages.myPlugins = with pkgs.vimPlugins; {
          start = [
            vim-nix
            vim-surround
            gruvbox-nvim
            vim-oscyank
          ];
          opt = [ ];
        };
        customRC = ''
          " FIXME
        '';
      };
      withRuby = false;
      withNodeJs = false;
      withPython3 = false;
    })
  ];

  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      trusted-public-keys = [
        "jupiter:2laywrj8EfgDWW8GnDkIPuONvzMyrIirdAPWkvSIU0g="
      ];
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
    supportedLocales = [ "de_DE.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" ];
  };

  time.timeZone = "Europe/Amsterdam";

  users.users.barnabas = {
    isNormalUser = true;
    uid = 1000;
    shell = pkgs.nushell;
    extraGroups = [ "wheel" "video" "audio" "dialout" "networkmanager" ];
    # FIXME: too lazy
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJQ+TsvKvdWG+9KLVeg5N4y1Ce1jr/fP3ELTHVWLxZOR" ];
  };

  boot.tmp.useTmpfs = true;

  networking.firewall.enable = true;

  # increase fd limits because they're way too low
  security.pam.loginLimits = [
    { domain = "*"; item = "nofile"; type = "soft"; value = "65536"; }
    { domain = "*"; item = "nofile"; type = "hard"; value = "65536"; }
  ];

  security.pki.certificateFiles = [ ../../../home_ca.crt ];

  services.fwupd.enable = true;

  services.tailscale.enable = true;
}
