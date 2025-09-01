{ config, ... }:
let
  domain = "lldap.home.5kw.li";
in
{
  services.lldap = {
    enable = true;
    environment = {
      LLDAP_JWT_SECRET_FILE = "/var/secrets/lldap/jwt_secret";
    };
    settings = {
      ldap_base_dn = "dc=5kw,dc=li";
      ldap_user_email = "admin@home.5kw.li";
      http_url = "https://${domain}";
      database_url = "postgresql:///lldap?host=/run/postgresql";
      ldap_user_pass_file = "/var/secrets/lldap/admin_pass";
    };
  };

  users = {
    users.lldap = {
      extraGroups = [ "secrets" ];
      group = "lldap";
      isSystemUser = true;
    };
    groups.lldap = { };
  };

  services.postgresql = {
    ensureDatabases = [ "lldap" ];
    ensureUsers = [
      {
        name = "lldap";
        ensureDBOwnership = true;
      }
    ];
  };

  systemd.services.lldap = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };

  services.caddy.extraConfig = ''
    ${domain} {
      reverse_proxy localhost:${toString config.services.lldap.settings.http_port}
    }
  '';
}
