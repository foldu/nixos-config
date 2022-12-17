{ pkgs, ... }: {
  environment.systemPackages = [
    pkgs.compsize
  ];

  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/" ];
  };

  virtualisation.docker.storageDriver = "btrfs";
}
