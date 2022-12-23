{ config, lib, pkgs, home-network, ... }:
let
  nfsMount = mountpoint: {
    device = "${home-network.devices.saturn.vip}:${mountpoint}";
    fsType = "nfs";
    options = [
      # NOTE: soft mounts can cause corruption but I'd rather have a 
      # single corrupted file than nfs hanging
      "soft"
      "retrans=3"

      "noauto"
      "noatime"
      "x-systemd.automount"
      "x-systemd.mount-timeout=10"
      "timeo=14"
      "x-systemd.idle-timeout=1min"
      "_netdev"
    ];
  };
in
{
  fileSystems = {
    "/run/media/torrents" = nfsMount "/srv/media/aux/downloads";
    "/run/media/img" = nfsMount "/srv/media/cia/data/img";
    "/run/media/music" = nfsMount "/srv/media/cia/data/music";
    "/run/media/beets-lib" = nfsMount "/srv/media/cia/data/beets-lib";
    "/run/media/videos" = nfsMount "/srv/media/main/vid";
    "/run/media/cache" = nfsMount "/srv/media/cia/cache";
    "/run/media/samba" = nfsMount "/srv/media/main/smb";
    "/run/media/other" = nfsMount "/srv/media/main/other";
  };
}
