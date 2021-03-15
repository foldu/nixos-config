{ pkgs, config, lib, ... }:
let
  syncthingDevices = (import ../../secrets).syncthingDevices;
in
{
  networking.firewall = {
    allowedTCPPorts = [
      # syncthing file transfer
      22000
    ];
    allowedUDPPorts = [
      # syncthing discovery
      21027
    ];
  };

  services.syncthing =
    let
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
      declarative = {
        devices = otherDevices;
        folders = {
          "/home/barnabas/downloads" = mkSharedShare "downloads";
          "/home/barnabas/uni" = mkSharedShare "uni";
          "/home/barnabas/org" = mkSharedShare "org";
          "/home/barnabas/.local/share/mpd/playlists" = mkSharedShare "playlists";
        };
      };
    };
}
