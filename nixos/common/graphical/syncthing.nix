{
  config,
  lib,
  home-network,
  ...
}:
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
        venus = {
          id = "7QLRH3I-32ELROX-SSYZXEI-BAZYYDW-AA5ASUJ-RVGY4EG-KDYT66K-XFMPVQW";
          addresses = [ "tcp://${devices.venus.vip}:${toString syncthingPort}" ];
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
      dataDir = "/home/barnabas";
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
