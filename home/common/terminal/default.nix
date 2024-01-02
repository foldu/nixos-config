{ pkgs, inputs, ... }: {
  imports = [
    ./nushell
    ./wezterm
    ./yazi
  ];

  xdg.configFile."src-manage/config.json".text = builtins.toJSON {
    config.src_dir = "~/src";
    hosts."git.home.5kw.li".flatten = true;
  };

  programs.neovim = {
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
    neofetch
    rename
    man-pages
  ];

  programs.broot = {
    enable = true;
    settings = {
      skin = (builtins.fromTOML (builtins.readFile "${inputs.kanagawa-theme}/extras/broot_kanagawa.toml")).skin;
    };
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

  programs.fzf.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv = {
      enable = true;
    };
  };
}
