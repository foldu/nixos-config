{ config, lib, pkgs, ... }: {
  imports = [
    ./nebula-dns.nix
  ];

  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";
  };
}
