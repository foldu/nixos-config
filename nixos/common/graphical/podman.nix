{ ... }:
{
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  systemd.timers.podman-auto-update = {
    enable = true;
    timerConfig.OnCalendar = "03:00";
  };
  boot.enableContainers = false;
}
