{
  pkgs,
  config,
  lib,
  ...
}:
{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
    dataDir = "/var/postgres/${config.services.postgresql.package.psqlSchema}";
  };

  boot.kernel.sysctl."net.core.rmem_max" = 2500000;

  # environment.systemPackages = [
  #   (
  #     let
  #       # XXX specify the postgresql package you'd like to upgrade to.
  #       # Do not forget to list the extensions you need.
  #       newPostgres = pkgs.postgresql_17.withPackages (pp: [
  #         # pp.plv8
  #       ]);
  #       cfg = config.services.postgresql;
  #     in
  #     pkgs.writeScriptBin "upgrade-pg-cluster" ''
  #       set -eux
  #       # XXX it's perhaps advisable to stop all services that depend on postgresql
  #       systemctl stop postgresql
  #
  #       export NEWDATA="/var/postgres/${newPostgres.psqlSchema}"
  #
  #       export NEWBIN="${newPostgres}/bin"
  #
  #       export OLDDATA="${cfg.dataDir}"
  #       export OLDBIN="${cfg.package}/bin"
  #
  #       install -d -m 0700 -o postgres -g postgres "$NEWDATA"
  #       cd "$NEWDATA"
  #       sudo -u postgres $NEWBIN/initdb -D "$NEWDATA" ${lib.escapeShellArgs cfg.initdbArgs}
  #
  #       sudo -u postgres $NEWBIN/pg_upgrade \
  #         --old-datadir "$OLDDATA" --new-datadir "$NEWDATA" \
  #         --old-bindir $OLDBIN --new-bindir $NEWBIN \
  #         "$@"
  #     ''
  #   )
  # ];
}
