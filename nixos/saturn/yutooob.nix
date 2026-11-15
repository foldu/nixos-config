{
  config,
  inputs,
  pkgs,
  ...
}:
let
  domain = "yutooob.home.5kw.li";
  port = 3001;
  yutooob = inputs.yutooob.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  imports = [ inputs.yutooob.nixosModules.default ];

  services.yutooob = {
    enable = true;
    package = yutooob;
    publicUrl = "https://${domain}";
    inherit port;

    # Caddy is the only way in, and it is on this host, so the backend answers
    # on loopback. The module cannot infer that from web.enable, which is off.
    bindAddress = "127.0.0.1";

    # Caddy sets X-Forwarded-For; without this every client shares one
    # rate-limit bucket.
    trustProxy = true;

    oidc = {
      issuer = "https://auth.home.5kw.li";
      clientId = "yutooob";
      clientSecretFile = config.sops.secrets."yutoob/oidc-client-secret".path;
    };

    session.secretFile = config.sops.secrets."yutoob/session-secret".path;
  };

  # Both are only read by the unit's LoadCredential, so root ownership is fine.
  sops.secrets."yutoob/oidc-client-secret" = { };
  sops.secrets."yutoob/session-secret" = { };

  # The SPA and the API share one origin, as the module's nginx vhost would.
  # handle blocks are sorted by matcher specificity, so /api/* wins.
  services.caddy.virtualHosts.${domain}.extraConfig = ''
    handle /api/* {
      reverse_proxy 127.0.0.1:${toString port} {
        # Segments stream back through /api/proxy: this is nginx's
        # proxy_buffering off and its 300s read/write timeouts.
        flush_interval -1
        transport http {
          read_timeout 300s
          write_timeout 300s
        }
      }
    }

    handle {
      encode zstd gzip

      root * ${yutooob}/share/yutooob/web

      # Vite names assets by content hash, so they never change.
      @assets path /assets/*
      header @assets Cache-Control "public, max-age=31536000, immutable"

      try_files {path} /index.html
      file_server
    }
  '';
}
