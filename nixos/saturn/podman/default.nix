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

  # Only the schedule is set here: podman ships podman-auto-update.service, and
  # the containers it moves are the ones with autoUpdate = "registry".
  systemd.timers.podman-auto-update = {
    enable = true;
    timerConfig.OnCalendar = "03:00";
    wantedBy = [ "multi-user.target" ];
  };
}
