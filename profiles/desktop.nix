{ config, lib, pkgs, ... }: {
  imports = [
    ./home/dns.nix
    ./generic.nix
  ];

  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";
  };
}
