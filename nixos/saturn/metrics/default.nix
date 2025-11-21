{
  pkgs,
  lib,
  config,
  outputs,
  ...
}:
let
  vmPort = 8428;
  vlPort = 9428;
in
{
  imports = [
    # ../../common/alertmanager
    ./telegraf-inputs/saturn.nix
    ./alerts
  ];

  services.victoriametrics = {
    enable = true;
    listenAddress = ":${toString vmPort}";
    extraOptions = [
      "-vmalert.proxyURL=http://localhost:8880"
    ];
  };

  services.victorialogs = {
    enable = true;
    listenAddress = ":${toString vlPort}";
  };

  services.prometheus.alertmanager.webExternalUrl = "https://alertmanager.home.5kw.li";

  services.caddy.virtualHosts =
    let
      proxyWithAuth = port: ''
        encode zstd gzip

        @has_valid_token header Authorization {env.METRICS_AUTH_TOKEN}
        @has_auth_header header Authorization *

        handle @has_valid_token {
          reverse_proxy :${toString port}
        }

        handle @has_auth_header {
          respond "Unauthorized" 401
        }

        handle {
          forward_auth https://auth.home.5kw.li {
            uri /api/authz/forward-auth
            copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
            header_up Host {upstream_hostport}
          }
          reverse_proxy :${toString port}
        }
      '';
    in
    {
      "metrics.home.5kw.li".extraConfig = proxyWithAuth vmPort;

      "logs.home.5kw.li".extraConfig = proxyWithAuth vlPort;
    };
}
