{ config, ... }:
let
  domain = "invidious.home.5kw.li";
  companionPort = "8282";
in
{
  services.invidious = {
    enable = true;
    inherit domain;
    port = 4299;
    settings = {
      db = {
        user = "invidious";
        dbname = "invidious";
      };
      https_only = true;
      external_port = 443;
      address = "127.0.0.1";
      invidious_companion = [
        {
          private_url = "http://localhost:${companionPort}/companion";
        }
      ];
      invidious_companion_key = "aephahm5Ca2ut6ha";
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes;
    in
    {
      containers = {
        invidious-companion = {
          containerConfig = {
            environments = {
              SERVER_SECRET_KEY = "aephahm5Ca2ut6ha";
              PORT = "8282";
            };
            image = "quay.io/invidious/invidious-companion:latest";
            volumes = [
              "${volumes.invidious-companion-cache.ref}:/var/tmp/youtubei.js:rw"
            ];
            publishPorts = [
              "127.0.0.1:${companionPort}:${companionPort}"
            ];
            autoUpdate = "registry";
            noNewPrivileges = true;
            dropCapabilities = [ "ALL" ];
            readOnly = true;
          };
        };
      };
      volumes.invidious-companion-cache.volumeConfig = { };
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
