{ config, lib, pkgs, ... }: {
  imports = [
    ./home/dns.nix
  ];

  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";
  };
}
