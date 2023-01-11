{ pkgs, ... }: {
  environment.systemPackages = [
    pkgs.compsize
  ];

  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/" ];
  };

  virtualisation.docker.storageDriver = "btrfs";

  virtualisation.containers.storage.settings = {
    storage = {
      driver = "btrfs";
      graphroot = "/var/lib/containers/storage";
      runroot = "/run/containers/storage";
    };
  };
}
