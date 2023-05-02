{ lib, pkgs, ... }: {
  services.xserver.desktopManager = {
    gnome.enable = true;
    xterm.enable = lib.mkForce false;
  };

  environment.gnome.excludePackages = with pkgs.gnome; [
    cheese
    gedit
    pkgs.gnome-photos
    gnome-logs
    gnome-contacts
    gnome-music
    gnome-software
  ];

  # conflicts with tlp
  services.power-profiles-daemon.enable = false;

  environment.systemPackages = with pkgs.gnomeExtensions; [
    appindicator
    blur-my-shell
    just-perfection
    gnome-ui-tune
    pano
  ];

  # disable laptop melting service
  services.gnome.tracker-miners.enable = false;

  # gunome _still_ has no server side decorations and alacritty windows look weird
  # because of that
  environment.sessionVariables.WINIT_UNIX_BACKEND = "x11";

  services.gnome = {
    #gnome-online-miners.enable = lib.mkForce false;
    #gnome-user-share.enable = false;
    gnome-initial-setup.enable = false;
    gnome-remote-desktop.enable = false;
  };
}
