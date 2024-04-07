{ pkgs, lib, ... }:

let
  bluez = pkgs.callPackage ./clownz_5_65.nix { };
in
{
  hardware.bluetooth = {
    enable = true;
    package = bluez;
    # package = pkgs.bluez.overrideAttrs (oldAttrs: {
    #   dontStrip = true;
    #   NIX_CFLAGS_COMPILE = "-ggdb -Og";
    # });
    powerOnBoot = true;
  };

  systemd.services.bluetooth-mesh.aliases = [ "dbus-org.bluez.mesh.service" ];
  systemd.services.bluetooth.serviceConfig.ExecStart = [
    ""
    "${bluez}/libexec/bluetooth/bluetoothd -f /etc/bluetooth/main.conf"
  ];
  systemd.services.bluetooth-mesh.serviceConfig.ExecStart = [
    ""
    "${bluez}/libexec/bluetooth/bluetooth-meshd -d "
  ];
  # --io=hci0
}
