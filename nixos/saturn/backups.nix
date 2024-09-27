{ config, pkgs, ... }:
{
  services.borgbackup.jobs =
    let
      backupToExtSsd =
        args@{ ... }:
        {
          encryption.mode = "none";
          compression = "zstd";
          environment = {
            BORG_RSH = "ssh -i /home/barnabas/.ssh/backup";
            # I DON'T GIVE A SHIT
            BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK = "1";
          };
          repo = "ssh://borg@ceres.home.5kw.li/var/backup/postgres";
        }
        // args;
    in
    {
      #   postgres =
      #     let
      #       tmpBackup = "/tmp/postgres_backup";
      #     in
      #     backupToExtSsd {
      #       preHook = ''
      #         ${pkgs.sudo}/bin/sudo -u postgres mkdir -p ${tmpBackup} -m 700
      #         ${pkgs.sudo}/bin/sudo -u postgres ${config.services.postgresql.package}/bin/pg_dumpall > ${tmpBackup}/database.sql
      #       '';
      #       postHook = ''
      #         rm -rf ${tmpBackup}
      #       '';
      #       paths = [ "${tmpBackup}/database.sql" ];
      #       startAt = "daily";
      #     };
    };
}
