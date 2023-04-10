{ config, lib, pkgs, inputs, ... }:

let
  minimal-neovim = pkgs.neovim.override {
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
        luafile ${./config/init.lua}
      '';
    };
    withRuby = false;
    withNodeJs = false;
    withPython3 = false;
  };
in
{
  environment.systemPackages = with pkgs; [
    wget
    curl
    jq
    fd
    ripgrep
    carapace
    file
    libarchive
    unzip
    bat
  ] ++ lib.optional (!config.programs.neovim-ide.enable) minimal-neovim;

  programs.fish.enable = true;

  home-manager.users.barnabas = { config, ... }: {
    home.packages = with pkgs; [
      neofetch
      rename
    ];

    programs.tmux = {
      enable = true;
      shortcut = "x";
    };

    programs.htop = {
      enable = true;
      settings = {
        vimMode = true;
        # need to configure this because too many cores
        left_meters = [ "LeftCPUs2" "Memory" "Swap" ];
        right_meters = [ "RightCPUs2" "Tasks" "LoadAverage" "Uptime" ];
      };
    };

    programs.git = {
      enable = true;
      lfs.enable = true;
      delta.enable = true;
      userName = "foldu";
      userEmail = "foldu@protonmail.com";
      extraConfig = {
        init.defaultBranch = "master";
        pull.rebase = true;
      };
    };

    # FIXME: use builtins.readDir
    xdg.configFile."fish/functions/tmp-clone.fish".source = ./config/fish/functions/tmp-clone.fish;
    xdg.configFile."fish/functions/edit-link.fish".source = ./config/fish/functions/edit-link.fish;
    # FIXME: wrong format
    # xdg.configFile."fish/themes/kanagawa.fish".source = "${inputs.kanagawa-theme}/extras/kanagawa.fish";

    programs.fish = {
      enable = true;

      functions = {
        fish_greeting = "";
      };

      shellAbbrs = {
        usv = "systemctl --user";
        sv = "sudo systemctl";
        nr = "nixos-rebuild";
        nse = "nix search nixpkgs";
        nsh = "nix shell nixpkgs#";
        cdoc = "cargo doc --no-deps --open -p";
        o = "xdg-open";
      };

      shellAliases = {
        rm = "rm -v";
        cp = "cp -iv --reflink=auto";
        mv = "mv -iv";
        wlc = "wl-copy";
        wlp = "wl-paste";
        rsync = "rsync -av --info=progress2";
      };

      interactiveShellInit = ''
        # set features
        set -U fish_features stderr-nocaret qmark-noglob ampersand-nobg-in-token

        set -U tide_left_prompt_items context pwd git character
        set -U tide_right_prompt_items status cmd_duration jobs time
        set -U tide_time_color white
        set -U tide_character_icon \$

        fzf_configure_bindings --directory=\ct --history=\cr

        bind \cX\cE edit_command_buffer

        ${builtins.readFile "${inputs.kanagawa-theme}/extras/kanagawa.fish"}
      '';

      plugins = [
        {
          name = "tide";
          src = pkgs.fetchFromGitHub {
            owner = "IlanCosman";
            repo = "tide";
            rev = "v5.5.1";
            sha256 = "sha256-vi4sYoI366FkIonXDlf/eE2Pyjq7E/kOKBrQS+LtE+M=";
          };
        }
        {
          name = "fzf";
          src = pkgs.fetchFromGitHub {
            owner = "PatrickF1";
            repo = "fzf.fish";
            rev = "v9.5";
            sha256 = "sha256-ZdHfIZNCtY36IppnufEIyHr+eqlvsIUOs0kY5I9Df6A=";
          };
        }
      ];
    };

    programs.nushell = {
      enable = true;
    };

    xdg.configFile."nushell" = {
      source = ./config/nushell;
      recursive = true;
    };

    programs.fzf = {
      enable = true;
      enableFishIntegration = false;
    };

    programs.direnv = {
      enable = true;
      nix-direnv = {
        enable = true;
      };
    };
  };
}
