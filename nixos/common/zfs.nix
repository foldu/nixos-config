{ pkgs, ... }:
{
  services.zfs.autoScrub = {
    enable = true;
    interval = "weekly";
  };

  boot.supportedFilesystems = [ "zfs" ];

  virtualisation.docker.storageDriver = "zfs";

  virtualisation.podman.extraPackages = [ pkgs.zfs ];

  virtualisation.containers.storage.settings = {
    storage = {
      driver = "zfs";
      graphroot = "/var/lib/containers/storage";
      runroot = "/run/containers/storage";
    };
  };
}
