{ config, pkgs, lib, ... }: {
  imports = [
    ./nebula-dns.nix
  ];

  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";
    wifi = {
      backend = "iwd";
      powersave = true;
    };
  };

  services.upower.enable = true;

  services.tlp = {
    enable = true;
    settings = {
      START_CHARGE_THRESH_BAT0 = 70;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };
}
