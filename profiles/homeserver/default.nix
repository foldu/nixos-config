{ config, lib, pkgs, inputs, ... }: {
  imports = [
    ../generic.nix
    ./cachecache.nix
    ./file-server.nix
    ./gitea.nix
    ./hydra.nix
    ./jellyfin.nix
    ./libreddit.nix
    ./nitter.nix
    ./step-ca.nix
    ./transmission.nix
    ./vaultwarden.nix
    ./piped
    ./unifi.nix
    "${inputs.homeserver-sekret}"
  ];

  users.users.barnabas.extraGroups = [ "transmission" ];

  services.postgresql = {
    enable = true;
    dataDir = "/var/postgres/${config.services.postgresql.package.psqlSchema}";
  };

  services.borgbackup.jobs =
    let
      backupToExtSsd = args@{ ... }: {
        encryption.mode = "none";
        compression = "zstd";
        environment = {
          BORG_RSH = "ssh -i /home/barnabas/.ssh/backup";
          # I DON'T GIVE A SHIT
          BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK = "1";
        };
        repo = "ssh://borg@ceres.home.5kw.li/var/backup/postgres";
      } // args;
    in
    {
      postgres =
        let
          tmpBackup = "/tmp/postgres_backup";
        in
        backupToExtSsd {
          preHook = ''
            ${pkgs.sudo}/bin/sudo -u postgres mkdir -p ${tmpBackup} -m 700
            ${pkgs.sudo}/bin/sudo -u postgres ${config.services.postgresql.package}/bin/pg_dumpall > ${tmpBackup}/database.sql
          '';
          postHook = ''
            rm -rf ${tmpBackup}
          '';
          paths = [ "${tmpBackup}/database.sql" ];
          startAt = "daily";
        };
    };

  services.caddy = {
    enable = true;
    acmeCA = "https://ca.home.5kw.li:4321/acme/acme/directory";
    email = "webmaster@5kw.li";
    globalConfig = ''
      servers :443 {
      }
    '';
  };

  services.nginx.recommendedOptimisation = true;

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  networking.firewall.allowedUDPPorts = [
    80
    443
  ];

  virtualisation.oci-containers.backend = "podman";
}
