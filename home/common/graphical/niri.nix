{ pkgs, ... }:
{
  home.packages = with pkgs; [
    brightnessctl
  ];

  programs.quickshell.enable = true;
  programs.fuzzel.enable = true;
  # programs.swaylock.enable = true;
  # programs.waybar = {
  #   enable = true;
  # };
  # programs.niri = {
  #   enable = true;
  # };
}
