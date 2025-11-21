{ config, ... }:
let
  domain = "alertmanager.home.5kw.li";
in
{
  services.prometheus.alertmanager = {
    enable = true;
    environmentFile = "/var/secrets/alertmanager.env";
    checkConfig = false;
    configText = builtins.readFile ./alertmanager.yml;
    webExternalUrl = "https://${domain}";
  };

  services.caddy.virtualHosts.${domain}.extraConfig = ''
    encode zstd gzip
    forward_auth https://auth.home.5kw.li {
      uri /api/authz/forward-auth
      copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
      header_up Host {upstream_hostport}
    }
    reverse_proxy :${toString config.services.prometheus.alertmanager.port}
  '';
}
