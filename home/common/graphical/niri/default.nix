{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # needed for x11 on niri
    xwayland-satellite
  ];

  xdg.configFile = {
    "niri/config.kdl".source = ./config.kdl;
    # maybe just use a service for this? I don't think the tray stuff is up right after start, given how ass slow qt is
    "niri/launch-when-tray-ready.sh" = {
      executable = true;
      source = ./launch-when-tray-ready.sh;
    };
  };

}
