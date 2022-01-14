{ pkgs, config, ... }: {
  services.nitter = {
    enable = true;
    server = {
      hostname = "nitter.5kw.li";
      port = 3456;
    };
  };

  services.caddy.extraConfig = ''
    nitter.nebula.5kw.li {
      reverse_proxy localhost:${toString config.services.nitter.server.port}
    }
  '';
}
