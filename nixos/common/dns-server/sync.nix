{
  config,
  lib,
  home-network,
  ...
}:
let
  syncthingPort = 22000;
  devices = home-network.devices;
  blocklistDir = (import ./shared.nix).blocklistDir;
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
        saturn = {
          id = "PBV22J5-OZNR43I-KII2T2N-QWXJTUK-4EZ4I34-SJNTPAW-B3G6JQH-6JYTYQJ";
          addresses = [ "tcp://${devices.saturn.vip}:${toString syncthingPort}" ];
        };
        ceres = {
          id = "I2COOSQ-E2UT7CD-BDBIY36-CP3HCNZ-C5N3YUA-TIXDR64-DM6OKCE-7VUKOQG";
          addresses = [ "tcp://${devices.ceres.vip}:${toString syncthingPort}" ];
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
      user = "blocklist";
      group = "blocklist";
      dataDir = "${blocklistDir}";
      settings = {
        devices = syncthingDevices;
        folders = {
          "${blocklistDir}/shared" = mkSharedShare "shared";
        };
      };
    };
}
