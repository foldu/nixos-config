{ pkgs, inputs, ... }:
{
  imports = [
    ./nushell
    ./fish
  ];

  xdg.configFile."src-manage/config.json".text = builtins.toJSON {
    config.src_dir = "~/src";
    hosts."git.home.5kw.li".flatten = true;
    hosts."lab.home.5kw.li".flatten = true;
  };

  # programs.neovim = {
  #   package = pkgs.neovim;
  #   enable = true;
  # };

  programs.tmux = {
    enable = true;
    focusEvents = true;
    mouse = true;
    newSession = true;
    prefix = "C-Space";
    sensibleOnTop = true;
    plugins =
      let
        smart-splits = pkgs.tmuxPlugins.mkTmuxPlugin {
          pluginName = "smart-splits";
          version = "";
          src = pkgs.fetchFromGitHub {
            owner = "mrjones2014";
            repo = "smart-splits.nvim";
            rev = "9af865e451e55a9835fae6862dd7c55396870ecb";
            sha256 = "sha256-YkfLXyxwCG7lvPMpGUC93qhOyT6G5K9W+dCDtXQVi+s=";
          };
        };
      in
      [
        {
          plugin = smart-splits;
          extraConfig = ''
            set -g @plugin 'mrjones2014/smart-splits.nvim'
          '';
        }
      ];
  };

  home.packages = with pkgs; [
    dua
    wget
    curl
    jq
    fd
    ripgrep
    file
    git-absorb
    libarchive
    unzip
    bat
    fastfetch
    rename
    man-pages
    (inputs.src-manage.packages.${pkgs.system}.src-manage)
  ];

  programs.htop = {
    enable = true;
    settings = {
      vimMode = true;
      # need to configure this because too many cores
      left_meters = [
        "LeftCPUs2"
        "Memory"
        "Swap"
      ];
      right_meters = [
        "RightCPUs2"
        "Tasks"
        "LoadAverage"
        "Uptime"
      ];
    };
  };

  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        email = "foldu@protonmail.com";
        name = "foldu";
      };
    };
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user = {
        name = "foldu";
        email = "foldu@protonmail.com";
      };
      init.defaultBranch = "master";
      pull.rebase = true;
      diff.tool = "nvim_difftool";
      difftool.nvim_difftool.cmd = "nvim -c \"packadd nvim.difftool\" -c \"DiffTool $LOCAL $REMOTE\"";
    };
    includes = [
      {
        path = "/home/barnabas/.config/git/sekret";
      }
    ];
  };

  programs.difftastic = {
    enable = true;
    git.enable = true;
  };

  programs.fzf.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv = {
      enable = true;
    };
  };
}
