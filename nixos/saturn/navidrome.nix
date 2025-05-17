{ config, ... }:
{
  services.navidrome = {
    enable = true;
    settings = {
      MusicFolder = "/srv/media/blub/data/music";
    };
  };

  services.caddy.extraConfig = ''
    music.home.5kw.li {
      reverse_proxy localhost:${toString config.services.navidrome.settings.Port}
    }
  '';
}
