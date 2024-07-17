{ lib, pkgs, ... }:
{
  services.xserver = {
    excludePackages = [ pkgs.xterm ];
    desktopManager = {
      gnome.enable = true;
      xterm.enable = lib.mkForce false;
    };
  };

  programs.kdeconnect.package = pkgs.gnomeExtensions.gsconnect;

  environment.gnome.excludePackages =
    (with pkgs; [
      gedit
      gnome-photos
      epiphany
      cheese
    ])
    ++ (with pkgs.gnome; [
      gnome-logs
      gnome-contacts
      gnome-music
      gnome-software
    ]);

  environment.systemPackages = with pkgs.gnomeExtensions; [
    vitals
    paperwm
    appindicator
    just-perfection
    # pano
    vertical-workspaces
    gsconnect
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
