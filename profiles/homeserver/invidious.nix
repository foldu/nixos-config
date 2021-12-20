{ config, lib, pkgs, ... }: {
  services.invidious = {
    enable = true;
    domain = "invidious.nebula.5kw.li";
    port = 24325;
  };

  services.caddy.config = ''
    invidious.nebula.5kw.li {
      reverse_proxy localhost:${toString config.services.invidious.port}
    }
  '';
}
