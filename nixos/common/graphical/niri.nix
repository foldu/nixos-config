{ lib, ... }:
{
  # services.dbus.packages = with pkgs; [
  #   gcr
  #   gnome-settings-daemon
  # ];

  services.gvfs.enable = true;

  programs.niri = {
    enable = true;
  };
  xdg.portal.config.niri = {
    "org.freedesktop.impl.portal.FileChooser" = "kde";
    "org.freedesktop.impl.portal.Secret" = lib.mkForce "kwallet";
  };

  # needed for noctalia
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
}
