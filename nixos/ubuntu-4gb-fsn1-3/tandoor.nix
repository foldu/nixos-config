{ config, ... }:
{
  services.tandoor-recipes = {
    enable = true;
    extraConfig = {
      ENABLE_SIGNUP = "0";
    };
    database.createLocally = true;
  };

  services.caddy.extraConfig = ''
    recipes.5kw.li {
      encode zstd gzip
      reverse_proxy localhost:${toString config.services.tandoor-recipes.port}
    }
  '';
}
