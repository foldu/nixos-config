{ config, lib, pkgs, ... }: {
  services.transmission = {
    enable = true;
    settings = {
      download-dir = "/srv/media/aux/downloads";
      incomplete-dir = "/srv/media/aux/downloads/.incomplete";
      incomplete-dir-enabled = true;
      rpc-host-whitelist = "torrent.home.5kw.li";
      rpc-whitelist = "127.0.0.1,192.168.1.*,192.168.100.*,10.20.30.*";
      rpc-port = 9091;
    };
  };

  services.caddy.extraConfig = ''
    torrent.home.5kw.li {
      reverse_proxy localhost:${toString config.services.transmission.settings.rpc-port}
    }
  '';
}
