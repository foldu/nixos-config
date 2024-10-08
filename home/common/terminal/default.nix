{ pkgs, inputs, ... }:
{
  imports = [
    ./nushell
    ./wezterm
    ./fish
  ];

  xdg.configFile."src-manage/config.json".text = builtins.toJSON {
    config.src_dir = "~/src";
    hosts."git.home.5kw.li".flatten = true;
  };

  programs.neovim = {
    package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim;
    enable = true;
    withRuby = false;
    withNodeJs = false;
    withPython3 = false;
  };

  home.packages = with pkgs; [
    dua
    wget
    curl
    jq
    fd
    ripgrep
    file
    libarchive
    unzip
    bat
    fastfetch
    rename
    man-pages
  ];

  programs.broot = {
    enable = true;
    settings = {
      skin =
        (builtins.fromTOML (builtins.readFile "${inputs.kanagawa-theme}/extras/broot_kanagawa.toml")).skin;
    };
  };

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

  programs.git = {
    enable = true;
    lfs.enable = true;
    delta.enable = true;
    userName = "foldu";
    userEmail = "foldu@protonmail.com";
    includes = [
      {
        condition = "gitdir:~/uni/";
        path = "/home/barnabas/.config/git/uni";
      }
      {
        condition = "gitdir:~/eclipse-workspace/";
        path = "/home/barnabas/.config/git/uni";
      }
    ];
    extraConfig = {
      init.defaultBranch = "master";
      pull.rebase = true;
    };
  };

  programs.fzf.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv = {
      enable = true;
    };
  };
}
