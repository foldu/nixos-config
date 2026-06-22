{
  pkgs,
  lib,
  ...
}:
{
  virtualisation.podman = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  virtualisation.oci-containers.backend = "podman";

  systemd.timers.podman-auto-update = {
    enable = true;
    timerConfig.OnCalendar = "03:00";
    wantedBy = [ "multi-user.target" ];
  };
}
