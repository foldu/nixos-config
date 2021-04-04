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

  services.resolved.enable = false;
  systemd.network =
    let
      ip = "${home-network.devices.${config.networking.hostName}.ip}/${home-network.subnet}";
    in
    {
      enable = true;
      networks.home = {
        name = "enp5s0";
        address = [ ip ];
        dns = home-network.dns;
        gateway = [ home-network.gateway ];
      };
    };

  system.stateVersion = "20.09";
}
