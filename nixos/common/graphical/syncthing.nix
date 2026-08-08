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
      # VM hosting the copyparty share; only the cloud folder is shared with
      # it, so it deliberately stays out of syncthingDevices (which
      # mkSharedShare spreads over every folder).
      server = "ubuntu-4gb-fsn1-3";
    in
    {
      enable = true;
      user = "barnabas";
      group = "users";
      openDefaultPorts = true;
      dataDir = "/home/barnabas";
      settings = {
        devices = syncthingDevices // {
          ${server} = {
            id = "RGVFEK4-BXM2Y22-7WVKOQZ-ZEOKJ22-KZFZJ23-JVSMBIQ-PB3ESY3-D4UYCAH";
            # dial the VM directly; no discovery needed (VM doesn't announce)
            addresses = [ "tcp://ubuntu-4gb-fsn1-3.5kw.li:22000" ];
            dynamic = false;
          };
        };
        folders = {
          "downloads" = mkSharedShare "/home/barnabas/downloads";
          "uni" = mkSharedShare "/home/barnabas/uni";
          "sync" = mkSharedShare "/home/barnabas/sync";
          "ssh" = mkSharedShare "/home/barnabas/.ssh";
          "rclone" = mkSharedShare "/home/barnabas/.config/rclone";
          "omp" = (mkSharedShare "/home/barnabas/.omp/agent") // {
            ignorePatterns = [
              "secret-placeholder.key"
              "*.db"
              "*.db-*"
              "terminal-sessions"
              "last-changelog-version"
            ];
          };
          "cloud" = {
            path = "/home/barnabas/cloud";
            id = "syncthing-share";
            devices = [ server ];
            ignorePerms = false;
          };
        };
      };
    };
}
