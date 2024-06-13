{
  config,
  lib,
  pkgs,
  ...
}:
let
  torrentDir = "/srv/media/nvme1/data/torrents";
  configDir = "/var/lib/transmission/config";
  incompleteDir = "${torrentDir}/.incomplete";
  rpcPort = "9091";
  domain = "torrent.home.5kw.li";
  url = "https://${domain}";
in
{
  users.users.transmission = {
    isSystemUser = true;
    group = "transmission";
  };
  users.groups.transmission = { };

  virtualisation.oci-containers.containers.transmission = {
    image = "docker.io/haugene/transmission-openvpn";
    environment = {
      PUID = toString config.users.users.transmission.uid;
      PGID = toString config.users.groups.transmission.gid;
      TRANSMISSION_RPC_USERNAME = "barnabas";
      TRANSMISSION_DOWNLOAD_DIR = "/data";
      TRANSMISSION_INCOMPLETE_DIR = "/data/.incomplete";
      TRANSMISSION_RPC_PORT = rpcPort;
    };
    ports = [ "${rpcPort}:${rpcPort}" ];
    volumes = [
      "${configDir}:/config"
      "${torrentDir}:/data"
    ];
    extraOptions = [
      "--privileged"
      "--cap-add=NET_ADMIN"
      "--env-file=/var/secrets/transmission.env"
    ];
  };

  users.users.barnabas.extraGroups = [ "transmission" ];

  systemd.tmpfiles.rules = [
    "d ${torrentDir} 755 ${config.services.transmission.user} ${config.services.transmission.group}"
    "d ${incompleteDir} 755 ${config.services.transmission.user} ${config.services.transmission.group}"
    "z ${torrentDir} 755 ${config.services.transmission.user} ${config.services.transmission.group}"
    "z ${incompleteDir} 755 ${config.services.transmission.user} ${config.services.transmission.group}"
    "d ${configDir} 700 transmission transmission"
  ];

  systemd.services =
    let
      python = pkgs.python3.withPackages (ps: [ ps.transmission-rpc ]);
      defaultArgs = {
        serviceConfig = {
          ExecStart = "${python}/bin/python3 ${./start_stop_torrents.py}";
        };
        environment = {
          TRANSMISSION_URL = url;
          SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
        };
      };
    in
    {
      transmission-start-all = lib.attrsets.recursiveUpdate defaultArgs {
        environment.ACTION = "start-all";
      };
      transmission-stop-all = lib.attrsets.recursiveUpdate defaultArgs {
        environment.ACTION = "stop-all";
      };
    };

  systemd.timers = {
    transmission-start-all = {
      enable = true;
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* 02:00:00";
      };
    };
    transmission-stop-all = {
      enable = true;
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* 09:00:00";
      };
    };
  };

  services.caddy.extraConfig = ''
    ${domain} {
      reverse_proxy localhost:${rpcPort}
    }
  '';
}
