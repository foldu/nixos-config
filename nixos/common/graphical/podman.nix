{ ... }:
{
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  systemd.timers.podman-auto-update = {
    enable = true;
    timerConfig.OnCalendar = "daily";
    wantedBy = [ "multi-user.target" ];
  };
  boot.enableContainers = false;
}
