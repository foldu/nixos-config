{ config, lib, pkgs, ... }:

{
  networking.firewall =
    let
      range = { from = 1714; to = 1764; };
    in
    {
      allowedTCPPortRanges = [ range ];
      allowedUDPPortRanges = [ range ];
    };

  home-manager.users.barnabas = { ... }: {
    services.kdeconnect = {
      enable = true;
      indicator = true;
    };
  };
}
