{
  config,
  lib,
  ...
}:
{
  services.syncthing =
    let
      syncthingDevices = {
        jupiter = {
          id = "O7RPI7X-O7EEEJO-TH55KF5-64PE6MS-RPFJZ5B-LIA2ZEW-GJVBCHS-76W54AP";
        };
        venus = {
          id = "7QLRH3I-32ELROX-SSYZXEI-BAZYYDW-AA5ASUJ-RVGY4EG-KDYT66K-XFMPVQW";
        };
      };
      otherDevices = lib.filterAttrs (k: _: k != config.networking.hostName) syncthingDevices;
      allOtherDeviceNames = lib.attrNames otherDevices;
      mkSharedShare = path: {
        inherit path;
        devices = allOtherDeviceNames;
        ignorePerms = false;
      };
    in
    {
      enable = true;
      user = "barnabas";
      group = "users";
      openDefaultPorts = true;
      dataDir = "/home/barnabas";
      settings = {
        devices = syncthingDevices;
        folders = {
          "downloads" = mkSharedShare "/home/barnabas/downloads";
          "uni" = mkSharedShare "/home/barnabas/uni";
          "sync" = mkSharedShare "/home/barnabas/sync";
        };
      };
    };
}
