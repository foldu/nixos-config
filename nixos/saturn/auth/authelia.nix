{ config, lib, ... }:
let
  autheliaHomePort = 9923;
in
{
  services.redis.servers.authelia = {
    enable = true;
    user = "authelia-home";
  };

  services.postgresql = {
    ensureUsers = [ { name = "authelia-home"; } ];
    ensureDatabases = [ "authelia-home" ];
  };

  users.users.authelia-home = { };

  services.authelia.instances.home = {
    enable = true;
    settings = {
      theme = "auto";
      authentication_backend.ldap = {
        implementation = "lldap";
        address = "ldap://localhost:3890";
        base_dn = "dc=5kw,dc=li";
        users_filter = "(&(|({username_attribute}={input})({mail_attribute}={input})))";
        user = "uid=authelia,ou=people,dc=5kw,dc=li";
      };
      notifier = {
        disable_startup_check = false;
        filesystem.filename = "/var/lib/authelia-home/notifications";
      };
      access_control = {
        default_policy = "deny";
        rules = lib.mkAfter [
          {
            domain = "*.home.5kw.li";
            policy = "one_factor";
          }
        ];
      };
      storage.postgres = {
        address = "unix:///run/postgresql";
        database = "authelia-home";
        username = "authelia-home";
      };
      session = {
        redis.host = "/run/redis-authelia/redis.sock";
        cookies = [
          {
            domain = "home.5kw.li";
            authelia_url = "https://auth.home.5kw.li";
            inactivity = "1M";
            expiration = "3M";
            remember_me = "1y";
          }
        ];
      };
      log.level = "info";
      identity_providers.oidc = {
        cors = {
          endpoints = [
            "token"
            "authorization"
            "revocation"
            "introspection"
          ];
          allowed_origins_from_client_redirect_uris = true;
          allowed_origins = [ "https://auth.home.5kw.li" ];
        };
        authorization_policies.default = {
          default_policy = "one_factor";
          rules = [
            {
              policy = "deny";
              subject = "group:lldap_strict_readonly";
            }
          ];
        };
      };
      server = {
        endpoints.authz.forward-auth.implementation = "ForwardAuth";
        address = "tcp://:${toString autheliaHomePort}";
      };
    };

    settingsFiles = [
      ./oidc_clients.yml
    ];

    secrets = {
      jwtSecretFile = config.sops.secrets."authelia/jwt-secret".path;
      oidcIssuerPrivateKeyFile = config.sops.secrets."authelia/jwks".path;
      oidcHmacSecretFile = config.sops.secrets."authelia/hmac-secret".path;
      storageEncryptionKeyFile = config.sops.secrets."authelia/storage-secret".path;
      sessionSecretFile = config.sops.secrets."authelia/session-secret".path;
    };

    environmentVariables.AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = config.sops.secrets."authelia/ldap-password".path;
  };

  sops.secrets = {
    "authelia/jwt-secret" = {
      owner = "authelia-home";
      mode = "0600";
    };
    "authelia/jwks" = {
      owner = "authelia-home";
      mode = "0600";
    };
    "authelia/hmac-secret" = {
      owner = "authelia-home";
      mode = "0600";
    };
    "authelia/storage-secret" = {
      owner = "authelia-home";
      mode = "0600";
    };
    "authelia/session-secret" = {
      owner = "authelia-home";
      mode = "0600";
    };
    "authelia/ldap-password" = {
      owner = "authelia-home";
      mode = "0600";
    };
  };

  services.caddy.virtualHosts."auth.home.5kw.li".extraConfig = ''
    encode zstd gzip
    reverse_proxy :${toString autheliaHomePort}
  '';
}
