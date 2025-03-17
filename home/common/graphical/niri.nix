{ inputs, ... }:
{
  imports = [
    inputs.niri-flake.homeModules.niri
  ];

  # programs.fuzzel.enable = true;
  # programs.swaylock.enable = true;
  # programs.waybar = {
  #   enable = true;
  # };
  # programs.niri = {
  #   enable = true;
  # };
}
