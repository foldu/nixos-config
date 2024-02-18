{
  config,
  lib,
  pkgs,
  home-network,
  ...
}:
let
  nfsMount = mountpoint: {
    device = "${home-network.devices.saturn.vip}:${mountpoint}";
    fsType = "nfs";
    options = [
      # NOTE: soft mounts can cause corruption but I'd rather have a 
      # single corrupted file than nfs hanging
      "soft"
      "retrans=3"

      "vers=4.2"
      "noauto"
      "noatime"
      "x-systemd.automount"
      "x-systemd.mount-timeout=10"
      "timeo=5"
      "x-systemd.idle-timeout=1min"
      "_netdev"
    ];
  };
in
{
  fileSystems = {
    "/run/media/torrents" = nfsMount "/torrents";
    "/run/media/img" = nfsMount "/img";
    # TODO: check applications using absolute paths and change
    # path from beets-lib to music
    "/run/media/beets-lib" = nfsMount "/music";
    "/run/media/videos" = nfsMount "/videos";
    "/run/media/cache" = nfsMount "/cache";
    "/run/media/samba" = nfsMount "/smb";
    "/run/media/other" = nfsMount "/other";
  };
}
