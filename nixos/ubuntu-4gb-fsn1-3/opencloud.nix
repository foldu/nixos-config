{ config, ... }:
let
  radicalePort = 5321;
in
{
  services.opencloud = {
    enable = true;
    url = "https://cloud.5kw.li";
    environment = {
      OC_INSECURE = "true";
      OC_LOG_LEVEL = "error";
      OC_SHARING_PUBLIC_SHARE_MUST_HAVE_PASSWORD = "false";
      PROXY_TLS = "false";
    };
  };

  # services.radicale = {
  #   enable = true;
  #   settings = {
  #     server.hosts = "127.0.0.1:${toString radicalePort}";
  #     auth.type = "http_x_remote_user";
  #     # nixos settings generator doesn't support this
  #     # storage = {
  #     #   predefined_collections = {
  #     #     "def-addressbook" = {
  #     #       "D:displayname" = "Personal Address Book";
  #     #       tag = "VADDRESSBOOK";
  #     #     };
  #     #
  #     #     "def-calendar" = {
  #     #       "C:supported-calendar-component-set" = "VEVENT,VJOURNAL,VTODO";
  #     #       "D:displayname" = "Personal Calendar";
  #     #       tag = "VCALENDAR";
  #     #     };
  #     #   };
  #     # };
  #     web.type = "none";
  #   };
  # };

  #services.caddy.extraConfig = ''
  #  cloud.5kw.li {
  #      encode zstd gzip

  #      route {
  #          reverse_proxy /carddav/* /.well-known/carddav http://localhost:${toString radicalePort} {
  #              header_up X-Remote-User {http.request.header.X-Remote-User}
  #              header_up X-Script-Name /carddav
  #              header_down X-Access-Token
  #          }

  #          reverse_proxy /caldav/* /.well-known/caldav http://localhost:${toString radicalePort} {
  #              header_up X-Remote-User {http.request.header.X-Remote-User}
  #              header_up X-Script-Name /caldav
  #              header_down X-Access-Token
  #          }
  #          reverse_proxy * localhost:${toString config.services.opencloud.port}
  #      }
  #  }
  #'';

  services.caddy.extraConfig = ''
    cloud.5kw.li {
        encode zstd gzip

        reverse_proxy localhost:${toString config.services.opencloud.port}
    }
  '';
}
