{ ... }:
{
  # services.dbus.packages = with pkgs; [
  #   gcr
  #   gnome-settings-daemon
  # ];

  services.gvfs.enable = true;

  programs.niri = {
    enable = true;
  };

  # needed for noctalia
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
}
