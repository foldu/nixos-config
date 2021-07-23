{ config, lib, pkgs, ... }: {
  hardware.bluetooth = {
    enable = true;
    package = pkgs.bluezFull;
    powerOnBoot = false;
  };

  systemd.services.bluetooth-mesh.aliases = [ "dbus-org.bluez.mesh.service" ];
}
