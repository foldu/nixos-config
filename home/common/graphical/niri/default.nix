{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # needed for x11 on niri
    xwayland-satellite
  ];

  xdg.configFile = {
    "niri/config.kdl".source = ./config.kdl;
    "niri/launch-bitwarden.sh" = {
      executable = true;
      source = ./launch-bitwarden.sh;
    };
  };

}
