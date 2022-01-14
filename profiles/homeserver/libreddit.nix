{ pkgs, config, ... }: {
  services.libreddit = {
    enable = true;
    port = 7777;
  };

  services.caddy.extraConfig = ''
    reddit.nebula.5kw.li {
      reverse_proxy localhost:${toString config.services.libreddit.port}
    }
  '';
}
