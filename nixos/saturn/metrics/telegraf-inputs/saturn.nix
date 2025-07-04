{ ... }:
{
  services.telegraf.extraConfig.inputs = {
    http_response = [
      {
        urls = [ "https://torrent.home.5kw.li/transmission/web" ];
        response_status_code = 401;
        tags.host = "saturn";
      }
      {
        urls = [ "https://jellyfin.home.5kw.li/web/index.html" ];
        response_string_match = "jellyfin";
        tags.host = "saturn";
      }
      {
        urls = [ "https://git.home.5kw.li" ];
        response_string_match = "gitea";
        tags.host = "saturn";
      }
      {
        urls = [ "https://vaultwarden.home.5kw.li/alive" ];
        response_status_code = 200;
        tags.host = "saturn";
      }
      {
        urls = [ "https://miniflux.home.5kw.li" ];
        follow_redirects = true;
        response_string_match = "Miniflux";
        tags.host = "saturn";
      }
      {
        urls = [ "https://reddit.home.5kw.li" ];
        follow_redirects = true;
        response_string_match = "Redlib";
        tags.host = "saturn";
      }
      {
        urls = [ "https://lab.home.5kw.li" ];
        follow_redirects = true;
        response_string_match = "gitlab";
        tags.host = "saturn";
      }
      {
        urls = [ "https://music.home.5kw.li" ];
        follow_redirects = true;
        response_string_match = "Navidrome";
        tags.host = "saturn";
      }
      {
        urls = [ "https://ai.home.5kw.li" ];
        follow_redirects = true;
        response_string_match = "Open WebUI";
        tags.host = "saturn";
      }
    ];
  };
}
