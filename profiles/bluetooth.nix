{ config, lib, pkgs, ... }: {
  hardware.bluetooth = {
    enable = true;
    package = pkgs.enableDebugging pkgs.bluezFull;
    powerOnBoot = false;
  };

  systemd.services.bluetooth-mesh.aliases = [ "dbus-org.bluez.mesh.service" ];
  systemd.services.bluetooth.serviceConfig.ExecStart = [ "" "${pkgs.bluezFull}/libexec/bluetooth/bluetoothd -f /etc/bluetooth/main.conf -d" ];
  systemd.services.bluetooth-mesh.serviceConfig.ExecStart = [ "" "${pkgs.bluezFull}/libexec/bluetooth/bluetooth-meshd -d" ];
}

