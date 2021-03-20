{ config, lib, pkgs, ... }: {
  imports = [
    ../../profiles/home.nix
    ../../profiles/homeserver.nix
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

  services.resolved.enable = false;
  systemd.network = {
    enable = true;
    networks.home = {
      name = "enp5s0";
      address = [ "192.168.1.100/24" ];
      dns = [ "192.168.1.1" ];
      gateway = [ "192.168.1.1" ];
    };
  };

  system.stateVersion = "20.09";
}
