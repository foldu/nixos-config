{ inputs, pkgs, ... }:
{
  users.users.wrrr = {
    isSystemUser = true;
    group = "wrrr";
  };

  users.groups.wrrr = { };

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
    serviceConfig = {
      ExecStart = "${inputs.atchr.packages.${pkgs.system}.wrrr}/bin/wrrr";
      EnvironmentFile = "/var/secrets/wrrr.env";
      User = "wrrr";
      Group = "wrrr";
      Type = "simple";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
