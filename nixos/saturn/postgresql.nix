{ pkgs, config, ... }:
{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_14;
    dataDir = "/var/postgres/${config.services.postgresql.package.psqlSchema}";
  };

  boot.kernel.sysctl."net.core.rmem_max" = 2500000;
}
