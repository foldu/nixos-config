{ config, ... }: {
  services.nitter = {
    enable = true;
    server = {
      hostname = "nitter.5kw.li";
      port = 3456;
    };
    config.proxy = "";
  };

  services.caddy.extraConfig = ''
    nitter.home.5kw.li {
      reverse_proxy localhost:${toString config.services.nitter.server.port}
    }
  '';
}
