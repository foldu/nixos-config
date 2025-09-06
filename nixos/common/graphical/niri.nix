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

  services.displayManager.gdm.enable = true;

  environment.systemPackages = with pkgs; [
    xwayland-satellite
  ];
}
