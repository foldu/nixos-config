{
  config,
  ...
}:
let
  torrentDir = "/srv/media/fast/torrents";
  configDir = "/var/lib/transmission/config";
  watchDir = "${torrentDir}/watch";
  rpcPort = "9091";
  domain = "torrent.home.5kw.li";
in
{
  users.users.transmission = {
    isSystemUser = true;
    group = "transmission";
    uid = 987;
  };
  users.groups.transmission = {
    gid = 980;
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) pods;
    in
    {
      pods.gluetun-pott.podConfig = {
        publishPorts = [
          "${rpcPort}:${rpcPort}"
          "51413:51413"
          "51413:51413/udp"
        ];
      };
      containers = {
        transmission.unitConfig = {
          Requires = "gluetun.service";
        };
        transmission.containerConfig = {
          image = "docker.io/linuxserver/transmission:latest";
          environments = {
            PUID = toString config.users.users.transmission.uid;
            PGID = toString config.users.groups.transmission.gid;
            TZ = "Europe/Amsterdam";
          };
          environmentFiles = [ "/var/secrets/transmission.env" ];
          volumes = [
            "${configDir}:/config"
            "${torrentDir}:/downloads"
            "${watchDir}:/watch"
          ];
          networks = [ "container:gluetun" ];
          pod = pods.gluetun-pott.ref;
        };
        gluetun.containerConfig = {
          image = "docker.io/qmcgaw/gluetun:v3.39.1";
          addCapabilities = [ "NET_ADMIN" ];
          devices = [ "/dev/net/tun:/dev/net/tun" ];
          environmentFiles = [ "/var/secrets/gluetun.env" ];
          pod = pods.gluetun-pott.ref;
        };
      };
    };

  users.users.barnabas.extraGroups = [ "transmission" ];

  systemd.tmpfiles.rules = [
    "d ${torrentDir} 775 ${config.services.transmission.user} ${config.services.transmission.group}"
    "d ${watchDir} 775 ${config.services.transmission.user} ${config.services.transmission.group}"
    "Z ${torrentDir} 775 ${config.services.transmission.user} ${config.services.transmission.group}"
    "d ${configDir} 700 transmission transmission"
    "Z ${configDir} 700 transmission transmission"
  ];

  services.caddy.extraConfig = ''
    ${domain} {
      reverse_proxy localhost:${rpcPort}
    }
  '';
}
