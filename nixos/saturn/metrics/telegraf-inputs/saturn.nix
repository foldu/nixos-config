{ ... }:
{
  services.telegraf.extraConfig.inputs = {
    http_response = [
      {
        urls = [ "https://torrent.home.5kw.li/transmission/web" ];
        # it's transmission, will try to set some header which you're supposed to send back
        response_status_code = 409;
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
        urls = [ "https://piped.home.5kw.li" ];
        response_string_match = "Piped";
        tags.host = "saturn";
      }
      {
        urls = [ "https://pipedapi.home.5kw.li/config" ];
        response_string_match = "https://ytproxy.home.5kw.li";
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
        urls = [ "https://unifi.home.5kw.li" ];
        follow_redirects = true;
        response_string_match = "UniFi";
        tags.host = "saturn";
      }
    ];
  };
}
