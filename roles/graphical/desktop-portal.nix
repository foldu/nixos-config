{ pkgs, ... }:
{
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-wlr
    ];
    gtkUsePortal = true;
  };

  #home-manager.users.barnabas = { config, ... }: {
  #  # need to do this in an user service because otherwise Qt wouldn't pick up the correct environment variable
  #  # also FIXME: ugly hack because the thing refuses to get activated by dbus
  #  systemd.user.services.xdg-desktop-portal-kde-hack = {
  #    Service = {
  #      ExecStart = "${pkgs.xdg-desktop-portal-kde}/libexec/xdg-desktop-portal-kde";
  #    };
  #    Unit = {
  #      PartOf = [ "graphical-session.target" ];
  #    };
  #    Install = {
  #      WantedBy = [ "graphical-session.target" ];
  #    };
  #  };
  #};
}
