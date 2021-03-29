{ config, lib, pkgs, ... }:

let
  nice-neovim = pkgs.neovim.override {
    viAlias = true;
    vimAlias = true;
    withRuby = false;
    withNodeJs = false;
    withPython = false;
    withPython3 = false;
    configure = {
      packages.myPlugins = with pkgs.vimPlugins; {
        start = [
          nord-vim
          gruvbox
          lightline-vim
          vim-surround
          vim-repeat
          vim-rsi
          editorconfig-vim
          vim-which-key
          vim-highlightedyank
          vim-matchup
          vim-polyglot
          undotree
        ];
      };

      customRC = builtins.readFile ./config/init.vim;
    };
  };
in
{
  environment.systemPackages = with pkgs; [
    wget
    curl
    nice-neovim
    fd
    ripgrep
    file
    libarchive
    unzip
  ];

  programs.fish.enable = true;

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
      vimMode = true;
      # need to configure this because too many cores
      meters = {
        left = [ "LeftCPUs2" "Memory" "Swap" ];
        right = [ "RightCPUs2" "Tasks" "LoadAverage" "Uptime" ];
      };
    };

    programs.git = {
      enable = true;
      lfs.enable = true;
      userName = "foldu";
      userEmail = "foldu@protonmail.com";
      extraConfig = {
        init.defaultBranch = "master";
        pull.rebase = true;
      };
    };

    programs.fish = {
      enable = true;

      shellAbbrs = {
        sudo = "doas";
        usv = "systemctl --user";
        sv = "doas systemctl";
        nr = "nixos-rebuild";
        nse = "nix search nixpkgs";
        nsh = "nix shell nixpkgs#";
        o = "xdg-open";
        mpv = "celluloid";
      };

      shellAliases = {
        rm = "rm -v";
        cp = "cp -iv";
        mv = "mv -iv";
        cdoc = "cargo doc --no-deps --open -p";
        wlc = "wl-copy";
        wlp = "wl-paste";
      };

      interactiveShellInit = ''
        # nord theme
        set -U fish_color_normal normal
        set -U fish_color_command 81a1c1
        set -U fish_color_quote a3be8c
        set -U fish_color_redirection b48ead
        set -U fish_color_end 88c0d0
        set -U fish_color_error ebcb8b
        set -U fish_color_param eceff4
        set -U fish_color_comment 434c5e
        set -U fish_color_match --background=brblue
        set -U fish_color_selection white --bold --background=brblack
        set -U fish_color_search_match bryellow --background=brblack
        set -U fish_color_history_current --bold
        set -U fish_color_operator 00a6b2
        set -U fish_color_escape 00a6b2
        set -U fish_color_cwd green
        set -U fish_color_cwd_root red
        set -U fish_color_valid_path --underline
        set -U fish_color_autosuggestion 4c566a
        set -U fish_color_user brgreen
        set -U fish_color_host normal
        set -U fish_color_cancel -r
        set -U fish_pager_color_completion normal
        set -U fish_pager_color_description B3A06D yellow
        set -U fish_pager_color_prefix white --bold --underline
        set -U fish_pager_color_progress brwhite --background=cyan

        # set features
        set -U fish_features stderr-nocaret qmark-noglob
      '';

      plugins = [{
        name = "tide";
        src = pkgs.fetchFromGitHub {
          owner = "IlanCosman";
          repo = "tide";
          rev = "f9d47a8f4f67a17b64eb07fbebfba0398341f6b0";
          sha256 = "sha256-LOyE28hUzUU56DK9Y9QLJQW91WvEugooFaimTuL9HlQ=";
        };
      }];
    };

    programs.fzf.enable = true;

    programs.direnv = {
      enable = true;
      enableNixDirenvIntegration = true;
    };

  };
}
