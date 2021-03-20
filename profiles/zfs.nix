{ config, lib, pkgs, ... }: {
  services.zfs.autoScrub = {
    enable = true;
    interval = "weekly";
  };

  boot.supportedFilesystems = [ "zfs" ];
}
