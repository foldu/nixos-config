{ config, ... }:
let
  inherit (config.virtualisation.quadlet) pods;
in
{
  #  contains:
  #  SECRET_KEY
  #  POSTGRES_HOST=localhost
  #  POSTGRES_PORT=5432
  #  POSTGRES_DB=tandoor_recipes
  #  POSTGRES_USER=tandoor_recipes
  #  POSTGRES_PASSWORD
  sops.secrets."tandoor/env" = { };

  virtualisation.quadlet.pods.tandoor.podConfig = {
    publishPorts = [ "127.0.0.1:8080:8080" ];
  };

  virtualisation.quadlet.containers = {
    tandoor-db.containerConfig = {
      image = "docker.io/library/postgres:16-alpine";
      environmentFiles = [ config.sops.secrets."tandoor/env".path ];
      volumes = [ "tandoor_db:/var/lib/postgresql/data" ];
      pod = pods.tandoor.ref;
      autoUpdate = "registry";
    };

    tandoor-recipes = {
      containerConfig = {
        image = "docker.io/vabene1111/recipes:latest";
        environments = {
          ENABLE_SIGNUP = "0";
          # explicit; container failed once for some unknown reason by this not being defined
          ALLOWED_HOSTS = "recipes.5kw.li";
        };
        environmentFiles = [ config.sops.secrets."tandoor/env".path ];
        volumes = [
          "tandoor_staticfiles:/opt/recipes/staticfiles"
          "tandoor_mediafiles:/opt/recipes/mediafiles"
        ];
        pod = pods.tandoor.ref;
        autoUpdate = "registry";
      };
      # boot.sh runs `manage.py migrate`, but only once the DB accepts connections
      unitConfig = {
        Requires = [ "tandoor-db.service" ];
        After = [ "tandoor-db.service" ];
      };
    };
  };

  services.caddy.extraConfig = ''
    recipes.5kw.li {
      encode zstd gzip
      reverse_proxy localhost:8080
    }
  '';
}
