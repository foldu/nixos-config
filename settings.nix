{ pkgs, ... }: {
  font = {
    monospace = {
      pkg = pkgs.fira-mono;
      name = "Fira Mono";
      size = 12;
    };
    devMonospace = {
      pkg = pkgs.ubuntu_font_family;
      name = "Ubuntu Mono";
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
    videoPlayer = {
      pkg = pkgs.gnome.totem;
      command = "totem";
      desktopFile = "org.gnome.Totem.desktop";
    };
    graphicalEditor = {
      pkg = null;
      command = "emacsclient";
      desktopFile = "emacsclient.desktop";
    };
    # nautilus sucks but dolphin has too many buttons
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
