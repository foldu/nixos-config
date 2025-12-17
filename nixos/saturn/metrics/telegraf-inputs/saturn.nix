{ ... }:
{
  services.telegraf.extraConfig.inputs = {
    http_response = [
      {
        urls = [ "https://torrent.home.5kw.li/transmission/web" ];
        response_status_code = 401;
        response_timeout = "30s";
        tags.host = "saturn";
      }
      {
        urls = [ "https://jellyfin.home.5kw.li/web/index.html" ];
        response_string_match = "jellyfin";
        response_timeout = "30s";
        tags.host = "saturn";
      }
      {
        urls = [ "https://vaultwarden.home.5kw.li/alive" ];
        response_status_code = 200;
        response_timeout = "30s";
        tags.host = "saturn";
      }
      {
        urls = [ "https://miniflux.home.5kw.li" ];
        follow_redirects = true;
        response_string_match = "Miniflux";
        response_timeout = "30s";
        tags.host = "saturn";
      }
      # {
      #   urls = [ "https://reddit.home.5kw.li" ];
      #   follow_redirects = true;
      #   response_string_match = "Redlib";
      #   response_timeout = "30s";
      #   tags.host = "saturn";
      # }
      {
        urls = [ "https://lab.home.5kw.li/foldu/nixos-config" ];
        follow_redirects = true;
        response_string_match = "gitlab";
        response_timeout = "30s";
        tags.host = "saturn";
      }
      {
        urls = [ "https://music.home.5kw.li" ];
        follow_redirects = true;
        response_string_match = "Navidrome";
        response_timeout = "30s";
        tags.host = "saturn";
      }
      {
        urls = [ "https://ai.home.5kw.li" ];
        follow_redirects = true;
        response_string_match = "Open WebUI";
        response_timeout = "30s";
        tags.host = "saturn";
      }
    ];
  };
}
