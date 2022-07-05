{ config, lib, pkgs, inputs, ... }: {
  imports = [
    ../generic.nix
    ./cachecache.nix
    ./file-server.nix
    ./gitea.nix
    ./hydra.nix
    ./invidious.nix
    ./jellyfin.nix
    ./libreddit.nix
    ./nitter.nix
    ./secrets.nix
    ./step-ca.nix
    ./transmission.nix
    ./vaultwarden.nix
    ./piped
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
        repo = "ssh://borg@ceres.5kw.li/run/media/ext-ssd/backup";
      } // args;
    in
    {
      # this sucks but hey it works
      postgresExt =
        let
          tmpBackup = "/tmp/postgres_backup";
        in
        backupToExtSsd {
          preHook = ''
            mkdir -p ${tmpBackup}
            chown postgres:postgres ${tmpBackup}
            chmod 700 ${tmpBackup}
            ${pkgs.doas}/bin/doas -u postgres ${pkgs.bash}/bin/bash -c '${config.services.postgresql.package}/bin/pg_dumpall > ${tmpBackup}/database.sql'
          '';
          paths = [ tmpBackup ];
          startAt = "daily";
        };
    };

  services.caddy = {
    enable = true;
    acmeCA = "https://ca.5kw.li:4321/acme/acme/directory";
    email = "webmaster@5kw.li";
    globalConfig = ''
      servers :443 {
          protocol {
            experimental_http3
          }
      }
    '';
  };

  services.nginx.recommendedOptimisation = true;

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  virtualisation.oci-containers.backend = "podman";
}
