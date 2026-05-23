{ ... }:
{
  services.zfs.autoScrub = {
    enable = true;
    interval = "weekly";
  };

  boot.supportedFilesystems = [ "zfs" ];

  # prevent data loss from bad default
  boot.zfs.forceImportRoot = false;
}
