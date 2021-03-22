{ config, lib, pkgs, ... }: {
  imports = [
    ./secrets.nix
  ];

  users.users.gitlab.extraGroups = [ "secrets" ];
  systemd.tmpfiles.rules = [
    "Z /var/secrets/gitlab 500 gitlab gitlab"
  ];

  services.gitlab = {
    enable = true;
    host = "gitlab.5kw.li";
    secrets = {
      otpFile = "/var/secrets/gitlab/otp";
      jwsFile = "/var/secrets/gitlab/jws";
      dbFile = "/var/secrets/gitlab/db";
      secretFile = "/var/secrets/gitlab/secret";
    };
    initialRootPasswordFile = "/var/secrets/gitlab/initial_root_password";
    initialRootEmail = "webmaster@5kw.li";
  };

  networking.firewall.allowedTCPPorts = [ config.services.gitlab.port ];

  services.caddy.config = ''
    gitlab.5kw.li {
      reverse_proxy unix//run/gitlab/gitlab-workhorse.socket
    }
  '';
}
