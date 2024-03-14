{ ... }:
let
  port = 9324;
  addr = "miniflux.home.5kw.li";
in
{
  services.miniflux = {
    enable = true;
    config = {
      LISTEN_ADDR = "localhost:${toString port}";
      BASE_URL = "https://${addr}";
    };
    adminCredentialsFile = "/var/secrets/miniflux.env";
  };

  services.caddy.extraConfig = ''
    ${addr} {
      reverse_proxy localhost:${toString port}
    }
  '';
}
