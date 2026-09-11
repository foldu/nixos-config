{
  config,
  inputs,
  pkgs,
  ...
}:
let
  port = 4319;
in
{
  users.users.wrrr = {
    isSystemUser = true;
    group = "wrrr";
  };

  users.groups.wrrr = { };

  sops.secrets."wrrr/env" = { };

  services.postgresql = {
    ensureDatabases = [ "wrrr" ];
    ensureUsers = [
      {
        name = "wrrr";
        ensureDBOwnership = true;
      }
    ];
  };

  systemd.services.wrrr = {
    enable = true;
    description = "wrrr";
    environment = {
      WRRR_BIND_TO = "127.0.0.1:${toString port}";
    };
    serviceConfig = {
      ExecStart = "${inputs.atchr.packages.${pkgs.stdenv.hostPlatform.system}.wrrr}/bin/wrrr";
      EnvironmentFile = config.sops.secrets."wrrr/env".path;
      User = "wrrr";
      Group = "wrrr";
      Type = "simple";
    };
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];
  };

  services.caddy.extraConfig = ''
    wrrr.home.5kw.li {
      reverse_proxy localhost:${toString port}
    }
  '';
}
