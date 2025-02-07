{ config, pkgs, ... }:
{
  services.gitlab = {
    enable = true;
    databasePasswordFile = "/var/secrets/gitlab/db_password";
    initialRootPasswordFile = "/var/secrets/gitlab/initial_root_password";
    https = true;
    host = "lab.home.5kw.li";
    port = 443;
    user = "gitlab";
    group = "gitlab";
    registry = {
      enable = false;
      package = pkgs.gitlab-container-registry;
      externalAddress = "container-registry.home.5kw.li";
      externalPort = 443;
      certFile = "/var/gitlab/registry/container-registry.home.5kw.li.crt";
      keyFile = "/var/gitlab/registry/container-registry.home.5kw.li.key";
    };
    smtp = {
      enable = false;
      address = "localhost";
      port = 25;
    };
    secrets = {
      dbFile = "/var/secrets/gitlab/db";
      secretFile = "/var/secrets/gitlab/secret";
      otpFile = "/var/secrets/gitlab/otp";
      jwsFile = "/var/secrets/gitlab/jws";
    };
  };

  users.users.gitlab = {
    group = "gitlab";
    extraGroups = [ "secrets" ];
  };

  users.groups.gitlab = { };

  systemd.services.git-mirror-lab = {
    path = with pkgs; [
      git
      openssh
      curl
    ];
    environment = {
      STATE_DIR = "/var/gitlab/state/mirror-script";
      SSH_KEY_FILE = "/var/secrets/gitlab/automation_lab";
      GITLAB_HOST = "lab.home.5kw.li";
    };
    # needs GITLAB_TOKEN env var
    script = builtins.readFile ./mirror.sh;
    serviceConfig = {
      User = "gitlab";
      EnvironmentFile = "/var/secrets/gitlab/glab.env";
    };
    startAt = "*:0/10";
  };

  services.caddy.extraConfig = ''
    lab.home.5kw.li {
      reverse_proxy unix//run/gitlab/gitlab-workhorse.socket
    }

    container-registry.home.5kw.li {
      reverse_proxy http://localhost:${toString config.services.gitlab.registry.port}
    }
  '';
}
