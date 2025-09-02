{ config, pkgs, ... }:
{
  services.redlib = {
    enable = true;
    # package = pkgs.callPackage ./package.nix { };
    port = 7777;
  };

  services.caddy.extraConfig = ''
    reddit.home.5kw.li {
      reverse_proxy localhost:${toString config.services.redlib.port}
    }
  '';
}
