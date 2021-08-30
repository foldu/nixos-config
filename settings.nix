{ pkgs, ... }: {
  font = {
    monospace = {
      pkg = pkgs.fira-mono;
      name = "Fira Mono";
      size = 12;
    };
    devMonospace = {
      pkg = pkgs.vistafonts;
      name = "Consolas";
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
      pkg = pkgs.gnome3.evince;
      command = "evince";
      desktopFile = "org.gnome.Evince.desktop";
    };
    consoleEditor = {
      pkg = null;
      command = "nvim";
      desktopFile = "neovim.desktop";
    };
    imageViewer = {
      pkg = pkgs.gnome3.eog;
      command = "eog";
      desktopFile = "org.gnome.eog.desktop";
    };
    videoPlayer = {
      pkg = pkgs.gnome3.totem;
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
      pkg = pkgs.gnome3.nautilus;
      command = "nautilus";
      desktopFile = "org.gnome.Nautilus.desktop";
    };
    torrentClient = {
      pkg = pkgs.transmission-remote-gtk;
      command = "transmission-remote-gtk";
      desktopFile = "io.github.TransmissionRemoteGtk.desktop";
    };
  };
}
