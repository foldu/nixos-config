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

      "auth.anonymous".enabled = false;

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

      # horrid syntax for a raw file content include
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
  sops.secrets."grafana/secret-key" = {
    owner = "grafana";
    group = "grafana";
    mode = "0400";
  };

  systemd.services.grafana.serviceConfig.EnvironmentFile =
    [ config.sops.secrets."grafana/env".path ];

  services.caddy.virtualHosts.${domain}.extraConfig = ''
    encode zstd gzip

    reverse_proxy 127.0.0.1:${toString port}
  '';
}
