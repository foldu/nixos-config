{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # needed for noctalia
    app2unit
    brightnessctl
    cava
    gpu-screen-recorder
    wlsunset

    # needed for x11 on niri
    xwayland-satellite
  ];

  xdg.configFile."niri/config.kdl".source = ./config.kdl;

  programs.quickshell = {
    enable = true;
    systemd.enable = true;
  };

  services.swayidle =
    let
      lockMonitor = "qs ipc call lockScreen lock";
    in
    {
      enable = true;
      events = [
        {
          command = lockMonitor;
          event = "before-sleep";
        }
        {
          command = "niri msg action power-on-monitors";
          event = "after-resume";
        }
      ];
      timeouts = [
        {
          timeout = 600;
          command = "niri msg action power-off-monitors";
        }
        {
          timeout = 300;
          command = lockMonitor;
        }
      ];
    };
}
