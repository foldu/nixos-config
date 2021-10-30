{ config, lib, pkgs, ... }: {
  services.transmission = {
    enable = true;
    settings = {
      download-dir = "/srv/media/aux/downloads";
      incomplete-dir = "/srv/media/aux/downloads/.incomplete";
      incomplete-dir-enabled = true;
      rpc-host-whitelist = "torrent.5kw.li";
      rpc-whitelist = "127.0.0.1,192.168.1.*,192.168.100.*";
    };
    port = 9091;
  };

  services.caddy.config = ''
    torrent.nebula.5kw.li {
      reverse_proxy localhost:${toString config.services.transmission.port}
    }
  '';
}
