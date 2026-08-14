{ config, ... }:
let
  domain = "dashboard.home.5kw.li";
  port = 3000;
in
{
  services.grafana = {
    enable = true;

    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = port;
        domain = domain;
        root_url = "https://${domain}";
      };

      # no anonymous access; everything goes through authelia + grafana login
      "auth.anonymous".enabled = false;

      # sign in via authelia OIDC; client id/secret come from the sops env
      # file (GF_AUTH_GENERIC_OAUTH_CLIENT_ID/SECRET)
      "auth.generic_oauth" = {
        enabled = true;
        name = "Authelia";
        allow_sign_up = true;
        scopes = "openid profile email groups";
        auth_url = "https://auth.home.5kw.li/api/oidc/authorization";
        token_url = "https://auth.home.5kw.li/api/oidc/token";
        api_url = "https://auth.home.5kw.li/api/oidc/userinfo";
        email_attribute_name = "email";
        role_attribute_path = "contains(groups[*], 'admins') && 'Admin' || 'Viewer'";
        use_pkce = true;
      };

      # secret key for signing datasource settings; value via file provider
      # pointing at the sops secret (avoids leaking it into the nix store)
      security.secret_key = "\$\${FILE:${config.sops.secrets."grafana/secret-key".path}}";
    };

    provision.datasources.settings.datasources = [
      {
        name = "VictoriaMetrics";
        uid = "victoriametrics";
        type = "prometheus";
        url = "http://127.0.0.1:8428";
        access = "proxy";
        isDefault = true;
        editable = true;
      }
    ];

    provision.dashboards.settings.providers = [
      {
        name = "default";
        options.path = "${./dashboards}";
      }
    ];
  };

  sops.secrets."grafana/env" = { };
  # grafana reads this via the $${FILE:...} provider as its own user
  sops.secrets."grafana/secret-key" = {
    owner = "grafana";
    group = "grafana";
    mode = "0400";
  };

  systemd.services.grafana.serviceConfig.EnvironmentFile =
    [ config.sops.secrets."grafana/env".path ];

  services.caddy.virtualHosts.${domain}.extraConfig = ''
    encode zstd gzip

    forward_auth https://auth.home.5kw.li {
      uri /api/authz/forward-auth
      copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
      header_up Host {upstream_hostport}
    }

    reverse_proxy 127.0.0.1:${toString port}
  '';
}
