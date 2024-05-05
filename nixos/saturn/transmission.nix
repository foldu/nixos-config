{ config, ... }:
let
  torrentDir = "/srv/media/nvme1/data/torrents";
  configDir = "/var/lib/transmission/config";
  incompleteDir = "${torrentDir}/.incomplete";
  rpcPort = "9091";
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

  services.caddy.extraConfig = ''
    torrent.home.5kw.li {
      reverse_proxy localhost:${rpcPort}
    }
  '';
}
