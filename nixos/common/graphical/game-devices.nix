{ pkgs, ... }:
{
  services.udev.packages = [ pkgs.game-devices-udev-rules ];

  hardware.uinput.enable = true;
}
