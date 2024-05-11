{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.compsize ];

  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/" ];
  };

  virtualisation.podman.extraPackages = [ pkgs.btrfs-progs ];
}
