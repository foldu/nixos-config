{ config, ... }:
let
  domain = "invidious.home.5kw.li";
in
{

  services.invidious = {
    enable = true;
    inherit domain;
    port = 4299;
    settings.db = {
      user = "invidious";
      dbname = "invidious";
    };
  };

  services.caddy.extraConfig = ''
    ${domain} {
      handle /vi/* {
        header Cache-Control "public, max-age=604800"
      }
      reverse_proxy localhost:${toString config.services.invidious.port}
    }
  '';
}
