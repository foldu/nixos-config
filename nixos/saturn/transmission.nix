{ config, ... }:
let
  torrentDir = "/srv/media/cia/data/torrents";
  incompleteDir = "${torrentDir}/.incomplete";
in
{
  services.transmission = {
    enable = true;
    settings = {
      download-dir = torrentDir;
      incomplete-dir = incompleteDir;
      incomplete-dir-enabled = true;
      rpc-host-whitelist = "torrent.home.5kw.li";
      rpc-whitelist = "127.0.0.1,192.168.1.*,192.168.100.*,10.20.30.*";
      rpc-port = 9091;
    };
  };

  users.users.barnabas.extraGroups = [ "transmission" ];

  systemd.tmpfiles.rules = [
    "d ${torrentDir} 755 ${config.services.transmission.user} ${config.services.transmission.group}"
    "d ${incompleteDir} 755 ${config.services.transmission.user} ${config.services.transmission.group}"
    "z ${torrentDir} 755 ${config.services.transmission.user} ${config.services.transmission.group}"
    "z ${incompleteDir} 755 ${config.services.transmission.user} ${config.services.transmission.group}"
  ];

  services.caddy.extraConfig = ''
    torrent.home.5kw.li {
      reverse_proxy localhost:${toString config.services.transmission.settings.rpc-port}
    }
  '';
}
