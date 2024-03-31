{ inputs, pkgs, ... }:
let
  #internalIp = "10.88.0.42";
  backendHostname = "pipedapi.home.5kw.li";
  frontendHostname = "piped.home.5kw.li";
  ytproxyHostname = "ytproxy.home.5kw.li";
  ytproxySockdir = "/run/ytproxy";
  internalIp = "10.88.1.25";
  frontendPort = "4456";
  varnishPort = "4099";
  backendPort = "4455";
  writeNuScript = inputs.nix-stuff.packages.${pkgs.system}.writeNuScript;
in
{
  imports = [ inputs.nix-stuff.nixosModules.podman-pods ];
  users.users.piped = {
    isSystemUser = true;
    group = "piped";
  };
  users.groups.piped = { };

  # START_TERRIBLE_HACK
  # terrible hack, user namespaces w/ normal users give me a headache
  systemd.tmpfiles.rules = [ "d ${ytproxySockdir} 777 1000 caddy" ];

  systemd.services.fix-ytproxy-permissions = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "simple";
    script = ''
      while true; do
        chmod 777 -R ${ytproxySockdir} 
        ${pkgs.inotify-tools}/bin/inotifywait -r -e create ${ytproxySockdir} || exit 1
      done
    '';
  };

  # END_TERRIBLE_HACK

  services.postgresql = {
    ensureUsers = [
      {
        name = "piped";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [ "piped" ];
  };

  services.varnish = {
    enable = true;
    config = ''
      vcl 4.0;

      backend default {
        .host = "localhost:${backendPort}";
      }
    '';
    http_address = "127.0.0.1:${varnishPort}";
  };

  services.caddy.extraConfig = ''
    ${frontendHostname} {
      reverse_proxy localhost:${frontendPort}
    }
    ${backendHostname} {
      reverse_proxy localhost:${varnishPort}
    }
    ${ytproxyHostname} {
      # https://github.com/TeamPiped/Piped/issues/2915#issuecomment-1973844585
      uri replace "&ump=1" ""

      @ytproxy path /videoplayback* /api/v4/* /api/manifest/*
      route {
        header @ytproxy {
          Cache-Control private always
        }

        header / {
          Cache-Control "public, max-age=604800"
        }

        reverse_proxy unix/${ytproxySockdir}/actix.sock {
          header_up -CF-Connecting-IP
          header_up -X-Forwarded-For
          header_down -etag
          header_down -alt-svc
        }
      }
    }
  '';

  podman-pods.pods.piped = {
    ip = internalIp;
    ports = [
      "${backendPort}:8080"
      "${frontendPort}:80"
    ];
    containers = {
      frontend = {
        image = "docker.io/1337kavin/piped-frontend:latest";
        cmd = [
          "ash"
          "-c"
          "sed -i s/pipedapi.kavin.rocks/${backendHostname}/g /usr/share/nginx/html/assets/* && /docker-entrypoint.sh && nginx -g 'daemon off;'"
        ];
        environment.BACKEND_HOSTNAME = backendHostname;
      };

      ytproxy = {
        image = "docker.io/1337kavin/piped-proxy:latest";
        environment.UDS = "1";
        volumes = [ "${ytproxySockdir}:/app/socket" ];
      };

      backend = {
        image = "docker.io/1337kavin/piped:latest";
        volumes = [ "${./piped.properties}:/app/config.properties:ro" ];
      };
    };
  };

  services.postgresql = {
    authentication = ''
      host piped piped ${internalIp}/32 md5
    '';
    enableTCPIP = true;
  };

  systemd.services.piped-subscription-updater = {
    after = [ "network.target" ];
    environment.BASE = "https://${backendHostname}";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = writeNuScript {
        name = "piped-subscription-updater";
        file = ./piped-subscription-updater.nu;
      };
      RestartSec = "1minute";
      EnvironmentFile = "/var/secrets/piped-updater.env";
    };
  };

  systemd.timers.piped-subscription-updater = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "hourly";
  };
}
