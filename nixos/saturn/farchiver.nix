{ ... }:
let
  port = 8090;
  domain = "farchiver.home.5kw.li";
in
{
  services.farchiver = {
    enable = true;
    address = "127.0.0.1:${toString port}";
  };

  services.caddy.virtualHosts.${domain}.extraConfig = ''
    forward_auth https://auth.home.5kw.li {
      uri /api/authz/forward-auth
      copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
      header_up Host {upstream_hostport}
    }
    reverse_proxy 127.0.0.1:${toString port}
  '';
}
