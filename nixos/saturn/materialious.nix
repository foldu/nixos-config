{ config, ... }:
let
  port = "4398";
in
{
  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes;
    in
    {
      containers.materialious = {
        containerConfig = {
          image = "docker.io/wardpearce/materialious-full:latest";
          # contains COOKIE_SECRET
          environmentFiles = [ "/var/secrets/materialious.env" ];
          environments = {
            DATABASE_CONNECTION_URI = "sqlite:///materialious-data/materialious.db";
            PUBLIC_INTERNAL_AUTH = "false";
            PUBLIC_REQUIRE_AUTH = "false";
            PUBLIC_REGISTRATION_ALLOWED = "false";
            PUBLIC_CAPTCHA_DISABLED = "true";
            PUBLIC_DEFAULT_RETURNYTDISLIKES_INSTANCE = "https://returnyoutubedislikeapi.com";
            PUBLIC_DEFAULT_SPONSERBLOCK_INSTANCE = "https://sponsor.ajay.app";
            PUBLIC_DEFAULT_DEARROW_INSTANCE = "https://sponsor.ajay.app";
            PUBLIC_DEFAULT_DEARROW_THUMBNAIL_INSTANCE = "https://dearrow-thumb.ajay.app";
          };
          volumes = [
            "${volumes.materialious-data.ref}:/materialious-data"
          ];
          publishPorts = [
            "127.0.0.1:${port}:3000"
          ];
          autoUpdate = "registry";
        };
      };
      volumes.materialious-data.volumeConfig = { };
    };

  services.caddy.extraConfig = ''
    materialious.home.5kw.li {
      reverse_proxy localhost:${port}
    }
  '';
}
