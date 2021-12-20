{ config, lib, pkgs, inputs, ... }: {
  imports = [
    ../generic.nix
    ./vaultwarden.nix
    ./file-server.nix
    ./gitea.nix
    ./transmission.nix
    ./step-ca.nix
    ./libreddit.nix
    ./nitter.nix
    ./drone
    ./secrets.nix
    ./cachecache.nix
    ./invidious.nix
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
    ca = "https://ca.5kw.li:4321/acme/acme/directory";
    email = "webmaster@5kw.li";
  };

  services.nginx.recommendedOptimisation = true;

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  # podman is even buggier than docker
  # that's quite an accomplishment
  # TODO: get rid of containers alltogether
  virtualisation.oci-containers.backend = "docker";
}
