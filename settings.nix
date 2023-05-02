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
      command = "brave";
      desktopFile = "brave-browser.desktop";

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
      pkg = pkgs.gnome.eog;
      command = "eog";
      desktopFile = "org.gnome.eog.desktop";
    };
    emailClient = {
      pkg = pkgs.gnome.geary;
      command = "geary";
      desktopFile = "x-scheme-handler/mailto=org.gnome.Geary.desktop";
    };
    videoPlayer = {
      pkg = pkgs.celluloid;
      command = "celluloid";
      desktopFile = "io.github.celluloid_player.Celluloid.desktop";
    };
    graphicalEditor = {
      pkg = null;
      command = "nvim";
      desktopFile = "neovim.desktop";
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
