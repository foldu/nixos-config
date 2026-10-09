{
  config,
  lib,
  ...
}:
let
  musicDir = "/srv/media/blub/data/music";
  torrentDir = "/srv/media/fast/torrents";

  lidarrPort = 8686;
  prowlarrPort = 9696;

  # None of the Servarr apps can do OAuth of their own: AuthenticationType is
  # only None/Basic/Forms/External, and External means "the reverse proxy in
  # front of me has already authenticated the user" - it hands the request to
  # NoAuthenticationHandler, which accepts everything. Bootstrap.cs binds
  # <App>:Auth, so the method arrives as an env var instead of having to be
  # edited into config.xml on first run.
  #
  # Because the apps then do no authentication at all, their ports are
  # published on loopback only: caddy is the single way in. That matters more
  # than it looks, since a published podman port is DNATed and so crosses
  # FORWARD rather than INPUT - the nixos firewall does not cover it.
  mkArr =
    {
      name,
      image,
      volumes,
    }:
    {
      unitConfig = {
        Requires = "gluetun.service";
        After = [ "gluetun.service" ];
      };

      containerConfig = {
        inherit image;

        # the same identity beets wrote through the cifs mount as, so the
        # library's ownership doesn't have to change for lidarr to import
        environments = {
          PUID = toString config.users.users.barnabas.uid;
          PGID = toString config.users.groups.users.gid;
          TZ = "Europe/Amsterdam";
          "${lib.toUpper name}__AUTH__METHOD" = "External";
          "${lib.toUpper name}__AUTH__REQUIRED" = "Enabled";
        };

        volumes = [ "/var/lib/${name}:/config" ] ++ volumes;

        # the pod already shares gluetun's netns; the explicit network is what
        # the transmission container next door does, and it keeps the netns
        # pinned to gluetun even if the pod's infra container ever goes away
        networks = [ "container:gluetun" ];
        pod = config.virtualisation.quadlet.pods.gluetun-pott.ref;
        autoUpdate = "registry";
      };
    };

  proxyWithAuth = port: ''
    forward_auth https://auth.home.5kw.li {
      uri /api/authz/forward-auth
      copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
      header_up Host {upstream_hostport}
    }
    reverse_proxy 127.0.0.1:${toString port}
  '';
in
{
  virtualisation.quadlet = {
    pods.gluetun-pott.podConfig.publishPorts = [
      "127.0.0.1:${toString lidarrPort}:${toString lidarrPort}"
      "127.0.0.1:${toString prowlarrPort}:${toString prowlarrPort}"
    ];

    containers = {
      # lidarr imports out of the same /downloads transmission writes to, so
      # the paths in its database match the ones transmission reports and no
      # remote path mapping is needed. /music is the existing beets library -
      # adding it as a root folder links those files in place.
      lidarr = mkArr {
        name = "lidarr";
        image = "docker.io/linuxserver/lidarr:version-3.1.0.4875";
        volumes = [
          "${musicDir}:/music"
          "${torrentDir}:/downloads"
        ];
      };

      # prowlarr only feeds indexers to lidarr, it never touches the media
      prowlarr = mkArr {
        name = "prowlarr";
        image = "docker.io/linuxserver/prowlarr:version-2.6.5.5623";
        volumes = [ ];
      };
    };
  };

  # podman would create these as root and linuxserver's init would chown them
  # a moment later; creating them with the right owner upfront is one less
  # window where the container can't write its own config
  systemd.tmpfiles.rules = [
    "d /var/lib/lidarr 700 ${toString config.users.users.barnabas.uid} ${toString config.users.groups.users.gid}"
    "d /var/lib/prowlarr 700 ${toString config.users.users.barnabas.uid} ${toString config.users.groups.users.gid}"
  ];

  services.caddy.virtualHosts = {
    "lidarr.home.5kw.li".extraConfig = proxyWithAuth lidarrPort;
    "prowlarr.home.5kw.li".extraConfig = proxyWithAuth prowlarrPort;
  };
}
