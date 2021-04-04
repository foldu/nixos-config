{ config, lib, pkgs, ... }: {
  services.binary-cache-cache = {
    enable = true;
    resolver = "127.0.0.1 ipv6=off";
    port = 4830;
  };

  services.caddy.config = ''
    nix-cache-cache.5kw.li {
      reverse_proxy localhost:${toString config.services.binary-cache-cache.port}
    }
  '';
}
