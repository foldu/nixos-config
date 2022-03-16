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
    withPython = false;
    withPython3 = false;
  };
in
{
  environment.systemPackages = with pkgs; [
    wget
    curl
    fd
    ripgrep
    file
    libarchive
    unzip
    bat
  ] ++ lib.optional (!config.programs.neovim-ide.enable) minimal-neovim;

  environment.pathsToLink = [ "/share/zsh" ];

  programs.fish.enable = true;
  programs.zsh.enable = true;

  home-manager.users.barnabas = { config, ... }: {
    home.packages = with pkgs; [
      neofetch
      rename
      huh
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

    home.file = {
      ".zshrc".source = ./config/zsh/zshrc.zsh;
      ".zshenv".source = ./config/zsh/zshenv.zsh;
      ".p10k.zsh".source = ./config/zsh/p10k.zsh;
    };

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
        o = "xdg-open";
      };

      shellAliases = {
        rm = "rm -v";
        cp = "cp -iv --reflink=auto";
        mv = "mv -iv";
        cdoc = "cargo doc --no-deps --open -p";
        wlc = "wl-copy";
        wlp = "wl-paste";
        rsync = "rsync -v --info=progress2";
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
            rev = "v5.0.1";
            sha256 = "sha256-EjEVyWwAtVqPFDEo9QUUAQXlAMlmEmaO0sqmjZSKI5M=";
          };
        }
        {
          name = "fzf";
          src = pkgs.fetchFromGitHub {
            owner = "PatrickF1";
            repo = "fzf.fish";
            rev = "4f2fdba27479abe81f5519518bb5045764f114f6";
            sha256 = "sha256-meTdxqweHzyirXr/j24OkNNlV1Ki+nGYLmW0sXBmyGQ=";
          };
        }
      ];
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
