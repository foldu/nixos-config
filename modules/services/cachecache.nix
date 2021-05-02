{ pkgs, config, lib, ... }:


# fork of https://github.com/Mic92/stockholm/blob/858efe4734c20c0878a7f77d8eeb8c85cf05bb11/krebs/3modules/cachecache.nix
# which is a fork of https://gist.github.com/rycee/f495fc6cc4130f155e8b670609a1e57b

with lib;

let
  cfg = config.services.binary-cache-cache;

  nginxCfg = config.services.nginx;

  cacheDir = "/var/cache/nginx/nix-cache-cache";

  cacheFallbackConfig = {
    proxyPass = "$upstream_endpoint";
    extraConfig = ''
      # Default is HTTP/1, keepalive is only enabled in HTTP/1.1.
      proxy_http_version 1.1;

      # Remove the Connection header if the client sends it, it could
      # be "close" to close a keepalive connection
      proxy_set_header Connection "";

      # Needed for CloudFront.
      proxy_ssl_server_name on;

      proxy_set_header Host $proxy_host;
      proxy_cache nix_cache_cache;
      proxy_cache_valid 200 302 60m;
      proxy_cache_valid 404 1m;

      expires max;
      add_header Cache-Control $nix_cache_cache_header always;
    '';
  };
  indexDir = "/srv/www/nix-cache-cache";
in

{
  options = {
    services.binary-cache-cache = {
      enable = mkEnableOption "Nix binary cache cache";

      virtualHost = mkOption {
        type = types.str;
        default = "nix-cache";
        description = ''
          Name of the nginx virtualhost to use and setup.
        '';
      };

      port = mkOption {
        type = types.nullOr types.port;
        default = null;
        description = ''
          Port to listen on.
        '';
      };

      enableSSL = mkOption {
        type = types.bool;
        default = false;
        description = ''
          enable SSL via letsencrypt. Requires working dns resolution and open
          internet tls port.
        '';
      };

      resolver = mkOption {
        type = types.str;
        description = "Address of DNS resolver.";
        default = "1.1.1.1 ipv6=off";
        example = "127.0.0.1 ipv6=off";
      };

      indexFile = mkOption {
        type = types.path;
        default = pkgs.writeText "myindex" "<html>hello world</html>";
        description = ''
          Path to index.html file.
        '';
      };

      maxSize = mkOption {
        type = types.str;
        default = "16g";
        description = "Maximum cache size.";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.port != null -> cfg.enableSSL == false;
        message = "Can't use a custom port when enabling ssl.";
      }
    ];

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    systemd.tmpfiles.rules = [
      "d ${cacheDir} 700 ${nginxCfg.user} ${nginxCfg.group}"
      "Z ${cacheDir} 700 ${nginxCfg.user} ${nginxCfg.group}"
      "d ${indexDir} 700 ${nginxCfg.user} ${nginxCfg.group}"
      "Z ${indexDir} 700 ${nginxCfg.user} ${nginxCfg.group}"
      "L+ ${indexDir}/index.html - - - - ${cfg.indexFile}"
    ];

    services.nginx = {
      enable = true;

      appendHttpConfig = ''
        proxy_cache_path ${cacheDir}
          levels=1:2
          keys_zone=nix_cache_cache:100m
          max_size=${cfg.maxSize}
          inactive=365d
          use_temp_path=off;

        # Cache only success status codes; in particular we don't want
        # to cache 404s. See https://serverfault.com/a/690258/128321.
        map $status $nix_cache_cache_header {
          200     "public";
          302     "public";
          default "no-cache";
        }
      '';

      virtualHosts.${cfg.virtualHost} = {
        addSSL = cfg.enableSSL;
        enableACME = cfg.enableSSL;
        extraConfig = ''
          # Using a variable for the upstream endpoint to ensure that it is
          # resolved at runtime as opposed to once when the config file is loaded
          # and then cached forever (we don't want that):
          # see https://tenzer.dk/nginx-with-dynamic-upstreams/
          # This fixes errors like
          #
          #   nginx: [emerg] host not found in upstream "upstream.example.com"
          #
          # when the upstream host is not reachable for a short time when
          # nginx is started.
          resolver ${cfg.resolver} valid=10s;
          set $upstream_endpoint https://cache.nixos.org;
        '';

        listen = lib.mkIf (cfg.port != null) [
          {
            addr = "0.0.0.0";
            port = cfg.port;
          }
        ];

        locations."/" = {
          root = indexDir;
          index = "index.html";
          extraConfig = ''
            expires max;
            add_header Cache-Control $nix_cache_cache_header always;

            # Ask the upstream server if a file isn't available
            # locally.
            error_page 404 = @fallback;

            # Don't bother logging the above 404.
            log_not_found off;
          '';
        };

        locations."@fallback" = cacheFallbackConfig;

        # We always want to copy cache.nixos.org's nix-cache-info
        # file, and ignore our own, because `nix-push` by default
        # generates one without `Priority` field, and thus that file
        # by default has priority 50 (compared to cache.nixos.org's
        # `Priority: 40`), which will make download clients prefer
        # `cache.nixos.org` over our binary cache.
        locations."= /nix-cache-info" = cacheFallbackConfig;
      };
    };
  };
}
