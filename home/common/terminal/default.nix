{ pkgs, inputs, ... }:
{
  imports = [
    ./nushell
    ./fish
  ];

  xdg.configFile."src-manage/config.json".text = builtins.toJSON {
    config.src_dir = "~/src";
    hosts."git.home.5kw.li".flatten = true;
  };

  # programs.neovim = {
  #   package = pkgs.neovim;
  #   enable = true;
  # };

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
    delta.enable = true;
    userName = "foldu";
    userEmail = "foldu@protonmail.com";
    includes = [
      {
        path = "/home/barnabas/.config/git/sekret";
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
