{ config, lib, pkgs, home-network, ... }: {
  imports = [
    ../../profiles/home.nix
    ../../profiles/homeserver
    ../../profiles/server.nix
    ../../profiles/x86.nix
    ../../profiles/zfs.nix
    ../../profiles/home-dns.nix
    ./hardware-configuration.nix
  ];
  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/sdc";
  };

  networking.hostId = "964725e9";

  networking.interfaces.enp6s0.useDHCP = true;

  virtualisation.podman = {
    enable = true;
    extraPackages = [ pkgs.zfs ];
  };

  virtualisation.containers.storage.settings = {
    storage = {
      driver = "zfs";
      graphroot = "/var/lib/containers/storage";
      runroot = "/run/containers/storage";
    };
  };

  services.postgresql.package = pkgs.postgresql_14;

  system.stateVersion = "20.09";
}
