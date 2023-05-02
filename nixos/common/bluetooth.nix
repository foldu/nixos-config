{ pkgs, ... }: {
  hardware.bluetooth = {
    enable = true;
    # package = pkgs.bluez.overrideAttrs (oldAttrs: {
    #   dontStrip = true;
    #   NIX_CFLAGS_COMPILE = "-ggdb -Og";
    # });
    powerOnBoot = false;
  };

  systemd.services.bluetooth-mesh.aliases = [ "dbus-org.bluez.mesh.service" ];
  systemd.services.bluetooth.serviceConfig.ExecStart = [ "" "${pkgs.bluez}/libexec/bluetooth/bluetoothd -f /etc/bluetooth/main.conf" ];
  systemd.services.bluetooth-mesh.serviceConfig.ExecStart = [ "" "${pkgs.bluez}/libexec/bluetooth/bluetooth-meshd -d " ];
  # --io=hci0
}
