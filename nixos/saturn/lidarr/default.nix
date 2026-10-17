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
  jackettPort = 9117;
  # 8080 is open-webui's on this host; kickdown takes its listen port from here.
  kickdownPort = 8088;

  # Every app below runs in the gluetun pod: its traffic has to egress the VPN,
  # and sharing that network namespace is also how the apps reach each other on
  # 127.0.0.1 (lidarr to jackett, prowlarr to flaresolverr).
  mkApp =
    {
      name,
      image,
      volumes ? [ ],
      environments ? { },
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
        }
        // environments;

        volumes = [ "/var/lib/${name}:/config" ] ++ volumes;

        # the pod already shares gluetun's netns; the explicit network is what
        # the transmission container next door does, and it keeps the netns
        # pinned to gluetun even if the pod's infra container ever goes away
        networks = [ "container:gluetun" ];
        pod = config.virtualisation.quadlet.pods.gluetun-pott.ref;
        autoUpdate = "registry";
      };
    };

  # None of the Servarr apps can do OAuth of their own: AuthenticationType is
  # only None/Basic/Forms/External, and External means "the reverse proxy in
  # front of me has already authenticated the user" - it hands the request to
  # NoAuthenticationHandler, which accepts everything. Bootstrap.cs binds
  # <App>:Auth, so the method arrives as an env var instead of having to be
  # edited into config.xml on first run. Jackett is not a Servarr app and has no
  # such variable - it does no authentication either.
  servarrAuth = name: {
    "${lib.toUpper name}__AUTH__METHOD" = "External";
    "${lib.toUpper name}__AUTH__REQUIRED" = "Enabled";
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
    # By default none of these apps authenticates its own users, so their ports
    # are published on loopback only: caddy is the single way in. That matters
    # more than it looks, since a published podman port is DNATed and so crosses
    # FORWARD rather than INPUT - the nixos firewall does not cover it.
    pods.gluetun-pott.podConfig.publishPorts = [
      "127.0.0.1:${toString lidarrPort}:${toString lidarrPort}"
      "127.0.0.1:${toString prowlarrPort}:${toString prowlarrPort}"
      "127.0.0.1:${toString jackettPort}:${toString jackettPort}"
      "127.0.0.1:${toString kickdownPort}:${toString kickdownPort}"
    ];

    # podman seeds a named volume from the image's own /config, which the
    # flaresolverr image already owns as its own user - so there is no uid to
    # guess, unlike the bind mounts above
    volumes.flaresolverr-config.volumeConfig = { };

    containers = {
      # lidarr imports out of the same /downloads transmission writes to, so
      # the paths in its database match the ones transmission reports and no
      # remote path mapping is needed. /music is the existing beets library -
      # adding it as a root folder links those files in place.
      lidarr = mkApp {
        name = "lidarr";
        image = "docker.io/linuxserver/lidarr:version-3.1.0.4875";
        environments = servarrAuth "lidarr";
        volumes = [
          "${musicDir}:/music"
          "${torrentDir}:/downloads"
        ];
      };

      # prowlarr only feeds indexers to lidarr, it never touches the media
      prowlarr = mkApp {
        name = "prowlarr";
        image = "docker.io/linuxserver/prowlarr:version-2.6.5.5623";
        environments = servarrAuth "prowlarr";
      };

      # A second indexer proxy, next to prowlarr. Lidarr adds it as a Torznab
      # indexer on http://127.0.0.1:9117/api/v2.0/indexers/all/results/torznab
      # with the API key from its dashboard; the two can feed lidarr at once.
      # FlareSolverr is one netns away at http://127.0.0.1:8191, but that URL
      # is a setting in Jackett's UI - it reads its server config from
      # ServerConfig.json, not from the environment.
      jackett = mkApp {
        name = "jackett";
        image = "docker.io/linuxserver/jackett:version-v0.24.2864";
      };

      # Ours (lab.home.5kw.li/foldu/kickdown): a web UI that searches Jackett and
      # drives Transmission, so it belongs next to both of them - and in this pod
      # so the tracker requests it makes on our behalf egress the VPN too.
      #
      # Not an mkApp: the image is our own Nix build rather than a linuxserver
      # one, so there is no PUID/PGID to set and nothing to keep in /config - it
      # takes its whole configuration from the environment. The tag is a commit
      # sha, which is what kickdown's CI publishes to the lab registry (alongside
      # <branch> and latest); bump it to move to a newer build.
      kickdown = {
        unitConfig = {
          Requires = "gluetun.service";
          After = [ "gluetun.service" ];
        };
        containerConfig = {
          image = "container-registry.home.5kw.li/foldu/kickdown:bf872568";
          environments = {
            HOST = "0.0.0.0";
            PORT = toString kickdownPort;
            JACKETT_URL = "http://127.0.0.1:${toString jackettPort}";
            TRANSMISSION_URL = "http://127.0.0.1:9091/transmission/rpc";
          };
          # the Jackett API key, and transmission's credentials when its RPC
          # authentication is on: see kickdown/env in secrets.yaml
          environmentFiles = [ config.sops.secrets."kickdown/env".path ];
          networks = [ "container:gluetun" ];
          pod = config.virtualisation.quadlet.pods.gluetun-pott.ref;
          autoUpdate = "registry";
        };
      };

      # Cloudflare answers rutracker's login POST with 403 before a single
      # credential is sent, so the fix has to happen below prowlarr. This
      # drives a real browser through the challenge and hands the cookie back.
      # It sits in the pod because that request has to egress the VPN as well.
      #
      # Nothing publishes its port: prowlarr and jackett share this netns, so
      # they just talk to http://127.0.0.1:8191 and the host never sees it.
      #
      # FlareSolverr and not Byparr, despite the maintainer suggesting both:
      # Byparr's request model has no postData field at all, so it can only
      # solve GET challenges, and this one is a POST to /forum/login.php.
      flaresolverr = {
        unitConfig = {
          Requires = "gluetun.service";
          After = [ "gluetun.service" ];
        };
        containerConfig = {
          image = "ghcr.io/flaresolverr/flaresolverr:v3.5.2";
          environments = {
            LOG_LEVEL = "info";
            TZ = "Europe/Amsterdam";
          };
          volumes = [ "${config.virtualisation.quadlet.volumes.flaresolverr-config.ref}:/config" ];
          networks = [ "container:gluetun" ];
          pod = config.virtualisation.quadlet.pods.gluetun-pott.ref;
          autoUpdate = "registry";
        };
      };
    };
  };

  # environmentFiles for the kickdown container; decrypted to a root-only file
  # that podman reads, so it never lands in the container's own environment
  sops.secrets."kickdown/env" = { };

  # podman would create these as root and linuxserver's init would chown them
  # a moment later; creating them with the right owner upfront is one less
  # window where the container can't write its own config
  systemd.tmpfiles.rules = [
    "d /var/lib/lidarr 700 ${toString config.users.users.barnabas.uid} ${toString config.users.groups.users.gid}"
    "d /var/lib/prowlarr 700 ${toString config.users.users.barnabas.uid} ${toString config.users.groups.users.gid}"
    "d /var/lib/jackett 700 ${toString config.users.users.barnabas.uid} ${toString config.users.groups.users.gid}"
  ];

  services.caddy.virtualHosts = {
    "lidarr.home.5kw.li".extraConfig = proxyWithAuth lidarrPort;
    "prowlarr.home.5kw.li".extraConfig = proxyWithAuth prowlarrPort;
    "jackett.home.5kw.li".extraConfig = proxyWithAuth jackettPort;
    "kickdown.home.5kw.li".extraConfig = proxyWithAuth kickdownPort;
  };
}
