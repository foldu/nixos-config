{ pkgs, ... }:
{
  # services.dbus.packages = with pkgs; [
  #   gcr
  #   gnome-settings-daemon
  # ];

  services.gvfs.enable = true;

  programs.niri = {
    enable = true;
  };

  services.displayManager.gdm = {
    enable = true;
    autoSuspend = false;
  };

  # needed for noctalia
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  environment.systemPackages = with pkgs; [
    xwayland-satellite
  ];
}
