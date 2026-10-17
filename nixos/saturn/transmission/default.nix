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
  sops.secrets = {
    "transmission/env" = { };
    "gluetun/env" = { };
  };

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
          After = [ "gluetun.service" ];
        };
        transmission.containerConfig = {
          image = "docker.io/linuxserver/transmission:latest";
          environments = {
            PUID = toString config.users.users.transmission.uid;
            PGID = toString config.users.groups.transmission.gid;
            TZ = "Europe/Amsterdam";
          };
          environmentFiles = [ config.sops.secrets."transmission/env".path ];
          volumes = [
            "${configDir}:/config"
            "${torrentDir}:/downloads"
            "${watchDir}:/watch"
          ];
          networks = [ "container:gluetun" ];
          pod = pods.gluetun-pott.ref;
          autoUpdate = "registry";
        };
        gluetun.containerConfig = {
          # v3 rather than latest: this is the pod every other app's traffic goes
          # through, so it should not follow a future major on its own.
          image = "docker.io/qmcgaw/gluetun:v3";
          addCapabilities = [ "NET_ADMIN" ];
          devices = [ "/dev/net/tun:/dev/net/tun" ];
          environmentFiles = [ config.sops.secrets."gluetun/env".path ];
          pod = pods.gluetun-pott.ref;
          autoUpdate = "registry";
        };
      };
    };

  users.users.barnabas.extraGroups = [ "transmission" ];

  systemd.tmpfiles.rules = [
    "d ${torrentDir} 775 ${config.services.transmission.user} ${config.services.transmission.group}"
    "d ${watchDir} 775 ${config.services.transmission.user} ${config.services.transmission.group}"
    # Lidarr builds its completed-download path out of transmission's own
    # download-dir (the "complete" below, set in the UI) and the category it
    # asks for, then fails a health check - "places downloads in
    # /downloads/complete/lidarr but Lidarr cannot see this directory" - until
    # that path exists, even before the first torrent. Transmission only makes
    # it when a download starts, so both it and the parent it writes into are
    # created here.
    "d ${torrentDir}/complete 775 ${config.services.transmission.user} ${config.services.transmission.group}"
    "d ${torrentDir}/complete/lidarr 775 ${config.services.transmission.user} ${config.services.transmission.group}"
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
