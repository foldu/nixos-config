{ config, lib, pkgs, ... }:

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
  base16-fish = pkgs.fetchFromGitHub {
    owner = "tomyun";
    repo = "base16-fish";
    rev = "675d53a0dd1aed0fc5927f26a900f5347d446459";
    sha256 = "sha256-Mc5Dwo6s8ljhla8cjnWymKqCcy3y0WDx51Ig82DS4VI=";
  };

  gruvbox-fun = builtins.readFile "${base16-fish}/functions/base16-gruvbox-dark-medium.fish";
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
        sv = "doas systemctl";
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
        ${gruvbox-fun}

        base16-gruvbox-dark-medium

        # set features
        set -U fish_features stderr-nocaret qmark-noglob

        set -U tide_left_prompt_items context pwd git prompt_char
        set -U tide_right_prompt_items status cmd_duration jobs time
        set -U tide_time_color white

        bind \cX\cE edit_command_buffer
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
      nix-direnv = {
        enable = true;
      };
    };
  };
}
