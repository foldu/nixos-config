{ config, lib, pkgs, ... }: {
  networking.networkmanager = {
    enable = true;
    dns = "dnsmasq";
  };
}
