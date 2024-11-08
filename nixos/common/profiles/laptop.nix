{ lib, ... }:
{
  imports = [
    ../generic
    ../systemd-resolved.nix
  ];

  # https://github.com/NixOS/nixpkgs/issues/180175
  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;

  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";
    wifi = {
      backend = "wpa_supplicant";
      powersave = true;
    };
  };

  services.cashewnix.settings.priority_config."0".timeout = "2s";

  services.upower.enable = true;

  systemd.tmpfiles.rules = [
    "w /sys/class/power_supply/BAT0/charge_start_threshold - - - - 70"
    "w /sys/class/power_supply/BAT0/charge_stop_threshold - - - - 80"
  ];
}
