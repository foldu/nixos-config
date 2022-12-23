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
    "/run/media/torrents" = nfsMount "/srv/nfs/torrents";
    "/run/media/img" = nfsMount "/srv/nfs/img";
    # TODO: check applications using absolute paths and change
    # path from beets-lib to music
    "/run/media/beets-lib" = nfsMount "/srv/nfs/music";
    "/run/media/videos" = nfsMount "/srv/nfs/videos";
    "/run/media/cache" = nfsMount "/srv/nfs/cache";
    "/run/media/samba" = nfsMount "/srv/nfs/smb";
    "/run/media/other" = nfsMount "/srv/nfs/other";
  };
}
