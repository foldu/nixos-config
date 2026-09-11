{ config, pkgs, ... }:
{
  services.gitlab = {
    enable = true;
    databasePasswordFile = config.sops.secrets."gitlab/db-password".path;
    initialRootPasswordFile = config.sops.secrets."gitlab/initial-root-password".path;
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
    backup = {
      startAt = "02:00";
      # on the blub zpool, separate disk from the VM root
      path = "/srv/media/blub/data/backups/gitlab";
      # module multiplies keepTime by 3600 (option is in hours)
      keepTime = 14 * 24; # 14 days
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
                secret._secret = config.sops.secrets."gitlab/auth-pass".path;
                redirect_uri = "https://lab.home.5kw.li/users/auth/openid_connect/callback";
              };
            };
          }
        ];
      };
    };
    secrets = {
      dbFile = config.sops.secrets."gitlab/db".path;
      secretFile = config.sops.secrets."gitlab/secret".path;
      otpFile = config.sops.secrets."gitlab/otp".path;
      jwsFile = config.sops.secrets."gitlab/jws".path;
      activeRecordPrimaryKeyFile = config.sops.secrets."gitlab/active-record-primary-key".path;
      activeRecordDeterministicKeyFile =
        config.sops.secrets."gitlab/active-record-deterministic-key".path;
      activeRecordSaltFile = config.sops.secrets."gitlab/active-record-salt".path;
    };
  };

  sops.secrets = {
    "gitlab/db-password" = {
      owner = "gitlab";
      mode = "0600";
    };
    "gitlab/initial-root-password" = {
      owner = "gitlab";
      mode = "0600";
    };
    "gitlab/auth-pass" = {
      owner = "gitlab";
      mode = "0600";
    };
    "gitlab/db" = {
      owner = "gitlab";
      mode = "0600";
    };
    "gitlab/secret" = {
      owner = "gitlab";
      mode = "0600";
    };
    "gitlab/otp" = {
      owner = "gitlab";
      mode = "0600";
    };
    "gitlab/jws" = {
      owner = "gitlab";
      mode = "0600";
    };
    "gitlab/active-record-primary-key" = {
      owner = "gitlab";
      mode = "0600";
    };
    "gitlab/active-record-deterministic-key" = {
      owner = "gitlab";
      mode = "0600";
    };
    "gitlab/active-record-salt" = {
      owner = "gitlab";
      mode = "0600";
    };
  };

  users.users.gitlab = {
    group = "gitlab";
  };

  users.groups.gitlab = { };

  services.caddy.extraConfig = ''
    lab.home.5kw.li {
      reverse_proxy unix//run/gitlab/gitlab-workhorse.socket
    }

    container-registry.home.5kw.li {
      reverse_proxy http://${config.services.gitlab.registry.settings.http.addr}
    }
  '';
}
