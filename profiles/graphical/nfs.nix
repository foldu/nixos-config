{ config, lib, pkgs, home-network, ... }:
let
  nfsMount = mountpoint: {
    device = "${home-network.devices.saturn.ip}:${mountpoint}";
    fsType = "nfs";
    options = [
      "noauto"
      "relatime"
      "x-systemd.automount"
      "x-systemd.mount-timeout=10"
      "timeo=14"
      # unmount after share unused for 5minutes
      "x-systemd.idle-timeout=5min"
    ];
  };
in
{
  fileSystems = {
    "/run/media/torrents" = nfsMount "/srv/media/aux/downloads";
    "/run/media/img" = nfsMount "/srv/media/cia/data/img";
    "/run/media/music" = nfsMount "/srv/media/cia/data/music";
    "/run/media/videos" = nfsMount "/srv/media/main/vid";
    "/run/media/cache" = nfsMount "/srv/media/cia/cache";
    "/run/media/samba" = nfsMount "/srv/media/main/smb";
    "/run/media/other" = nfsMount "/srv/media/main/other";
  };
}
