{ pkgs, lib, ... }:
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

  systemd.user.services = {
    quickshell = {
      Unit = {
        PartOf = [ "niri.service" ];
      };
      Install.WantedBy = lib.mkForce [ "niri.service" ];
    };
    swayidle = {
      Unit = {
        PartOf = [ "niri.service" ];
      };
      Install.WantedBy = lib.mkForce [ "niri.service" ];
    };
  };

  services.swayidle =
    let
      lockMonitor = "${pkgs.quickshell}/bin/qs ipc call lockScreen lock";
      niri = "${pkgs.niri}/bin/niri";
    in
    {
      enable = true;
      events = {
        "before-sleep" = lockMonitor;
        "after-resume" = "${niri} msg action power-on-monitors";
      };

      timeouts = [
        {
          timeout = 600;
          resumeCommand = "${niri} msg action power-on-monitors";
          command = "${niri} msg action power-off-monitors";
        }
        {
          timeout = 300;
          command = lockMonitor;
        }
      ];
    };
}
