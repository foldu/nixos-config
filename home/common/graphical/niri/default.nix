{ pkgs, ... }:
{
  home.packages = with pkgs; [
    brightnessctl
  ];

  xdg.configFile."niri/config.kdl".source = ./config.kdl;

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
