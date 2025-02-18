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
  start-stop-torrents = pkgs.buildGoModule {
    name = "start-stop-torrents";
    src = ./start-stop-torrents;
    vendorHash = "sha256-jnSdAsXlzQBpZer5eCdFjWp3CR8wmOd8Nv2XNdPvlXo=";
  };
in
{
  users.users.transmission = {
    isSystemUser = true;
    group = "transmission";
  };
  users.groups.transmission = { };

  virtualisation.quadlet.containers.transmission.containerConfig = {
    image = "docker.io/haugene/transmission-openvpn";
    environments = {
      PUID = toString config.users.users.transmission.uid;
      PGID = toString config.users.groups.transmission.gid;
      TRANSMISSION_RPC_USERNAME = "barnabas";
      TRANSMISSION_DOWNLOAD_DIR = "/data";
      TRANSMISSION_INCOMPLETE_DIR = "/data/.incomplete";
      TRANSMISSION_RPC_PORT = rpcPort;
    };
    publishPorts = [ "${rpcPort}:${rpcPort}" ];
    volumes = [
      "${configDir}:/config"
      "${torrentDir}:/data"
    ];
    environmentFiles = [ "/var/secrets/transmission.env" ];
    addCapabilities = [ "NET_ADMIN" ];
    podmanArgs = [ "--privileged" ];
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
      defaultArgs = {
        serviceConfig = {
          ExecStart = "${start-stop-torrents}/bin/start-stop-torrents";
        };
        environment = {
          TRANSMISSION_URL = "https://${domain}/transmission/rpc";
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
