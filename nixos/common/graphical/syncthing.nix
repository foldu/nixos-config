{ config, lib, home-network, ... }:
let
  syncthingPort = 22000;
  devices = home-network.devices;
in
{
  networking.firewall = {
    allowedTCPPorts = [
      # syncthing file transfer
      syncthingPort
    ];
    allowedUDPPorts = [
      # syncthing discovery
      21027
    ];
  };

  services.syncthing =
    let
      syncthingDevices = {
        jupiter = {
          id = "O7RPI7X-O7EEEJO-TH55KF5-64PE6MS-RPFJZ5B-LIA2ZEW-GJVBCHS-76W54AP";
          addresses = [ "tcp://${devices.jupiter.vip}:${toString syncthingPort}" ];
        };
        mars = {
          id = "SS573IT-UI75K4S-RLJYSXJ-5AEAYD6-QMFURGD-J75C5E5-O7DWS4G-35KOXAN";
          addresses = [ "tcp://${devices.mars.vip}:${toString syncthingPort}" ];
        };
      };
      otherDevices = lib.filterAttrs (k: _: k != config.networking.hostName) syncthingDevices;
      allOtherDeviceNames = lib.attrNames otherDevices;
      mkSharedShare = id: {
        inherit id;
        devices = allOtherDeviceNames;
      };
    in
    {
      enable = true;
      user = "barnabas";
      group = "users";
      configDir = "/home/barnabas/.config/syncthing";
      settings = {
        devices = syncthingDevices;
        folders = {
          "/home/barnabas/downloads" = mkSharedShare "downloads";
          "/home/barnabas/uni" = mkSharedShare "uni";
          "/home/barnabas/sync" = mkSharedShare "sync";
        };
      };
    };
}
