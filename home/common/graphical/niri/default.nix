{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    # needed for x11 on niri
    xwayland-satellite
  ];

  xdg.configFile."niri/config.kdl".source = ./config.kdl;

  systemd.user.services = {
    kwallet-pam-init = {
      Service.ExecStart = "${pkgs.kdePackages.kwallet-pam}/libexec/pam_kwallet_init";
      Unit = {
        PartOf = [ "niri.service" ];
      };
      Install.WantedBy = lib.mkForce [ "niri.service" ];
    };
    plasma-polkit-agent-niri = {
      Service = {
        ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
        BusName = "org.kde.polkit-kde-authentication-agent-1";
        Slice = "background.slice";
        After = "graphical-session.target";
        Requisite = "graphical-session.target";
        RestartSec = "5";
        Restart = "on-failure";
      };
      Unit = {
        PartOf = [ "niri.service" ];
      };
      Install.WantedBy = [ "niri.service" ];
    };
  };
}
