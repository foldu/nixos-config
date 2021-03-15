{ pkgs, config, ... }:
{
  # enable the bfq io scheduler for all matching devices
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="sd[a-z]|nvme[0-9]*", ATTR{queue/scheduler}="bfq"
  '';
}
