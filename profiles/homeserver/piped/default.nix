{ config, lib, pkgs, ... }:
let
  #internalIp = "10.88.0.42";
  backendHostname = "pipedapi.home.5kw.li";
  frontendHostname = "piped.home.5kw.li";
  ytproxyHostname = "ytproxy.home.5kw.li";
  ytproxySockdir = "/run/ytproxy";
  internalIp = "10.88.1.25";
  varnishPort = "4455";
  frontendPort = "4456";
in
{
  users.users.piped = {
    isSystemUser = true;
    group = "piped";
  };
  users.groups.piped = { };


  # START_TERRIBLE_HACK
  # terrible hack, user namespaces w/ normal users give me a headache
  systemd.tmpfiles.rules = [
    "d ${ytproxySockdir} 777 1000 caddy"
  ];

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
        ensurePermissions = {
          "DATABASE piped" = "ALL PRIVILEGES";
        };
      }
    ];
    ensureDatabases = [ "piped" ];
  };

  virtualisation.oci-containers.containers =
    let
      extraOptions = [ "--pod=piped-pott" ];
      user = "piped";
    in
    {
      piped-frontend = {
        image = "1337kavin/piped-frontend:latest";
        inherit extraOptions;
        cmd = [ "ash" "-c" "sed -i s/pipedapi.kavin.rocks/${backendHostname}/g /usr/share/nginx/html/assets/* && /docker-entrypoint.sh && nginx -g 'daemon off;'" ];
        #''
        #  ash -c 'sed -i s/pipedapi.kavin.rocks/${backendHostname}/g /usr/share/nginx/html/assets/* && /docker-entrypoint.sh && nginx -g "daemon off;"'
        #'';
        dependsOn = [ "piped-backend" ];
      };

      piped-ytproxy = {
        inherit extraOptions;
        image = "1337kavin/ytproxy:latest";
        volumes = [
          "${ytproxySockdir}:/app/socket"
        ];
      };

      piped-backend = {
        inherit extraOptions;
        image = "1337kavin/piped:latest";
        volumes = [
          "${./piped.properties}:/app/config.properties:ro"
        ];
      };

      piped-varnish = {
        inherit extraOptions;
        image = "varnish:7.0-alpine";
        volumes = [
          "./varnish.vcl:/etc/varnish/default.vcl:ro"
        ];
        dependsOn = [ "piped-backend" ];
      };
    };
  services.caddy.extraConfig = ''
        ${frontendHostname} {
          reverse_proxy localhost:${varnishPort}
        }
        ${backendHostname} {
          reverse_proxy localhost:${frontendPort}
        }
        ${ytproxyHostname} {
            @ytproxy path /videoplayback* /api/v4/* /api/manifest/*
            route {
    		header @ytproxy {
    			Cache-Control private always
    		}

    		header / {
    			Cache-Control "public, max-age=604800"
    		}

    		reverse_proxy unix/${ytproxySockdir}/http-proxy.sock {
    			header_up -CF-Connecting-IP
    			header_up -X-Forwarded-For
    			header_down -etag
    			header_down -alt-svc
    		}
    	  }
        }
  '';
  systemd.services.create-piped-pod = {
    serviceConfig.Type = "oneshot";
    wantedBy = [ "podman-piped-backend.service" ];
    script = ''
      ${config.virtualisation.podman.package}/bin/podman pod exists piped-pott || \
        ${config.virtualisation.podman.package}/bin/podman pod create -n piped-pott \
        -p '127.0.0.1:${frontendPort}:8080' \
        -p '127.0.0.1:${varnishPort}:80' \
        --ip ${internalIp}
    '';
  };

  services.postgresql = {
    authentication = ''
      host piped piped ${internalIp}/32 md5
    '';
    enableTCPIP = true;
  };
}
