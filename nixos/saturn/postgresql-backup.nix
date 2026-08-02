{ pkgs, config, ... }:
let
  # just backing up to the same host currently, could be improved
  walgEnv = {
    WALG_SSH_PREFIX = "ssh://saturn.home.5kw.li/srv/media/blub/data/backups/postgres";
    WALG_SSH_USERNAME = "backup";
    WALG_SSH_PRIVATE_KEY_PATH = config.sops.secrets."wal-g/sftp-key".path;
    WALG_COMPRESSION_METHOD = "zstd";
  };
in
{
  sops.secrets."wal-g/sftp-key" = {
    owner = "postgres";
    group = "postgres";
    mode = "0600";
  };

  services.postgresql.settings = {
    archive_mode = "on";
    archive_command = "${pkgs.wal-g}/bin/wal-g wal-push \"%p\"";
  };

  # archive_command runs inside postgres, so the storage config must be in
  # the postgres service environment (merged with the module's PGDATA/PGPORT)
  systemd.services.postgresql.environment = walgEnv;

  systemd.services.walg-backup-full = {
    after = [ "postgresql.service" ];
    serviceConfig = {
      User = "postgres";
      Group = "postgres";
      Type = "oneshot";
      ExecStart = "${pkgs.wal-g}/bin/wal-g backup-push ${config.services.postgresql.dataDir} --full";
    };
    environment = walgEnv;
  };
  systemd.timers.walg-backup-full = {
    wantedBy = [ "timers.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    timerConfig = {
      OnCalendar = "Sun 03:00";
      Persistent = true;
    };
  };

  systemd.services.walg-backup-delta = {
    after = [ "postgresql.service" ];
    serviceConfig = {
      User = "postgres";
      Group = "postgres";
      Type = "oneshot";
      ExecStart = "${pkgs.wal-g}/bin/wal-g backup-push ${config.services.postgresql.dataDir}";
    };
    environment = walgEnv;
  };
  systemd.timers.walg-backup-delta = {
    wantedBy = [ "timers.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    timerConfig = {
      OnCalendar = "Mon..Sat 03:00";
      Persistent = true;
    };
  };

  # count-based retention: keep the 4 most recent full chains (weekly fulls
  # => roughly a month)
  systemd.services.walg-delete = {
    after = [
      "walg-backup-full.service"
      "walg-backup-delta.service"
    ];
    serviceConfig = {
      User = "postgres";
      Group = "postgres";
      Type = "oneshot";
      ExecStart = "${pkgs.wal-g}/bin/wal-g delete retain FULL 4 --confirm";
    };
    environment = walgEnv;
  };
  systemd.timers.walg-delete = {
    wantedBy = [ "timers.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 03:30:00";
      Persistent = true;
    };
  };

  users.users.backup = {
    isSystemUser = true;
    group = "backup";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINzY49SFkq3YCfXDEyGQNTcLloQX3bVrdqQFcIJvEUEz pgbackrest-sftp@saturn"
    ];
  };
  users.groups.backup = { };

  # internal-sftp so the nologin backup user can accept sftp sessions
  # (external sftp-server execs through the user's shell and dies on nologin)
  services.openssh.sftpServerExecutable = "internal-sftp";
}
