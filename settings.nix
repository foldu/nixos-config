pkgs: {
  font = {
    monospace = {
      pkg = pkgs.fira-mono;
      name = "Fira Mono";
      size = 12;
    };
    devMonospace = {
      pkg = pkgs.fira-mono;
      name = "Fira Mono";
      size = 12;
    };
    documents = {
      pkg = pkgs.roboto-slab;
      name = "Roboto Slab";
      size = 11;
    };
    sans = {
      pkg = pkgs.inter;
      name = "Inter";
      size = 11;
    };
    serif = {
      pkg = pkgs.inter;
      name = "Inter";
      size = 11;
    };
  };
  apps = {
    browser = {
      pkg = null;
      command = "librewolf";
      desktopFile = "librewolf.desktop";
    };
    pdfViewer = {
      pkg = pkgs.gnome.evince;
      command = "evince";
      desktopFile = "org.gnome.Evince.desktop";
    };
    consoleEditor = {
      pkg = null;
      command = "nvim";
      desktopFile = "neovim.desktop";
    };
    imageViewer = {
      pkg = pkgs.loupe;
      command = "loupe";
      desktopFile = "org.gnome.Loupe.desktop";
    };
    emailClient = {
      pkg = pkgs.thunderbird;
      command = "thunderbird";
      desktopFile = "thunderbird";
    };
    videoPlayer = {
      pkg = pkgs.celluloid;
      command = "celluloid";
      desktopFile = "io.github.celluloid_player.Celluloid.desktop";
    };
    graphicalEditor = {
      pkg = pkgs.neovide;
      command = "neovide";
      desktopFile = "neovide.desktop";
    };
    fileBrowser = {
      pkg = pkgs.gnome.nautilus;
      command = "nautilus";
      desktopFile = "org.gnome.Nautilus.desktop";
    };
    torrentClient = {
      pkg = pkgs.fragments;
      command = "fragments";
      desktopFile = "de.haeckerfelix.Fragments.desktop";
    };
  };
}
