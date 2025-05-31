{
  home-network,
  config,
  ...
}:
let
  smbMount = mountpoint: {
    device =
      if config.networking.hostName == "jupiter" then
        "//${home-network.devices.saturn.ip}/${mountpoint}"
      else
        "//${home-network.devices.saturn.vip}/${mountpoint}";
    fsType = "cifs";
    options = [
      "x-systemd.automount"
      "noauto"
      "noatime"
      "_netdev"
      "x-systemd.idle-timeout=60s"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
      "credentials=${config.sops.secrets.samba-saturn-barnabas.path}"
      "uid=${toString config.users.users.barnabas.uid}"
      "gid=${toString config.users.groups.users.gid}"
    ];
  };
in
{
  sops.secrets.samba-saturn-barnabas = { };

  fileSystems = {
    "/run/media/barnabas/music" = smbMount "music";
    "/run/media/barnabas/other" = smbMount "other";
    "/run/media/barnabas/cache" = smbMount "cache";
    "/run/media/barnabas/torrents" = smbMount "torrents";
    "/run/media/barnabas/windows" = smbMount "trash";
  };
}
