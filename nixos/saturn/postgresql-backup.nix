{ lib, ... }:
let
  pgBackupRepo = "/srv/media/fast/postgres/backups";
  pgSpool = "/var/spool/pgbackrest";
in
{
  services.pgbackrest = {
    enable = true;

    settings = {
      compress-type = "zst";
      process-max = 2;

      # Async WAL archiving: archive-push acknowledges immediately by writing
      # to a local spool; a background process ships to the repo. PostgreSQL
      # never blocks on backup I/O.
      #
      # in the current setup this isn't really needed; due to everything being local on the same nvme,
      # but really nice if I ever decide to make proper backups to an external provider
      archive-async = true;
      spool-path = pgSpool;
    };

    repos.localhost = {
      path = pgBackupRepo;
      retention-full = 4;
      retention-diff = 14;
    };

    stanzas.default.jobs = {
      full = {
        type = "full";
        schedule = "Sun 03:00";
      };
      diff = {
        type = "diff";
        schedule = "Mon..Sat 03:00";
      };
    };
  };

  # postgres sandboxing prevents it from writing to the repo which
  # shows up as ROfs write error, so add it to ReadWritePaths
  systemd.services.postgresql.serviceConfig.ReadWritePaths = lib.mkAfter [
    pgBackupRepo
    pgSpool
  ];

  # postgres user writes WAL/spool; pgbackrest user reads data for backups.
  # the module adds both users to each other's groups
  systemd.tmpfiles.rules = [
    "d ${pgBackupRepo} 0770 postgres pgbackrest - -"
    "d ${pgSpool} 0770 postgres pgbackrest - -"
  ];
}
