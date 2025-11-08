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
      enable = true;
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
    extraConfig = {
      omniauth = {
        enabled = true;
        allow_single_sign_on = [ "openid_connect" ];
        sync_email_from_provider = "openid_connect";
        sync_profile_from_provider = [ "openid_connect" ];
        sync_profile_attributes = [ "email" ];
        auto_sign_in_with_provider = "openid_connect";
        block_auto_created_users = true;
        auto_link_user = [ "openid_connect" ];

        providers = [
          {
            name = "openid_connect";
            label = "Authelia";
            args = {
              name = "openid_connect";
              strategy_class = "OmniAuth::Strategies::OpenIDConnect";
              scope = [
                "openid"
                "profile"
                "email"
              ];
              response_type = "code";
              response_mode = "query";
              issuer = "https://auth.home.5kw.li";
              discovery = true;
              client_auth_method = "basic";
              uid_field = "preferred_username";
              send_scope_to_token_endpoint = true;
              pkce = true;
              client_options = {
                # For production, use secret management with _secret attribute
                identifier = "BUZmb2r5H~mUMqH_MwQwFGGP2KKJeD5nwMDn2DbzY4qXh2mSjzjaJHUxXdBT9aoK";
                secret._secret = "/var/secrets/gitlab/auth_pass";
                redirect_uri = "https://lab.home.5kw.li/users/auth/openid_connect/callback";
              };
            };
          }
        ];
      };
    };
    secrets = {
      dbFile = "/var/secrets/gitlab/db";
      secretFile = "/var/secrets/gitlab/secret";
      otpFile = "/var/secrets/gitlab/otp";
      jwsFile = "/var/secrets/gitlab/jws";
      activeRecordPrimaryKeyFile = "/var/secrets/gitlab/active_record_primary_key";
      activeRecordDeterministicKeyFile = "/var/secrets/gitlab/active_record_deterministic_key";
      activeRecordSaltFile = "/var/secrets/gitlab/active_record_salt";
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
