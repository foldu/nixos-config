{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # needed for noctalia
    brightnessctl
    cava
    gpu-screen-recorder
    wlsunset
  ];

  xdg.configFile."niri/config.kdl".source = ./config.kdl;

  programs.quickshell = {
    enable = true;
    systemd.enable = true;
  };
}
