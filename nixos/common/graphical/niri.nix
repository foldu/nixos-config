{ pkgs, inputs, ... }:
{
  # services.dbus.packages = with pkgs; [
  #   gcr
  #   gnome-settings-daemon
  # ];

  services.gvfs.enable = true;

  programs.niri = {
    enable = true;
  };

  environment.systemPackages = [
    pkgs.xwayland-satellite
  ];
}
