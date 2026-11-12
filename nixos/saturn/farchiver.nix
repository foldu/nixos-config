{ ... }:
let
  port = 8090;
  domain = "farchiver.home.5kw.li";
in
{
  services.farchiver = {
    enable = true;
    address = "127.0.0.1:${toString port}";
    # The archive outgrew the root pool, so its store lives with the rest of the
    # media on blub. The service account is created by the module, and the
    # directory has to be handed over to it once: chown -R farchiver:farchiver.
    dataDir = "/srv/media/blub/data/farchiver";
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
