{ inputs, ... }:
let
  openwebui-data = "/var/lib/openwebui";
in
{
  imports = [
    inputs.quadlet-nix.nixosModules.quadlet
  ];

  systemd.tmpfiles.rules = [
    "d ${openwebui-data} 700 root root"
  ];

  virtualisation.quadlet.autoEscape = true;

  virtualisation.quadlet.containers.open-webui = {
    containerConfig = {
      image = "ghcr.io/open-webui/open-webui:main";
      volumes = [
        "${openwebui-data}:/app/backend/data"
      ];
      autoUpdate = "registry";
      environmentFiles = [ "/var/secrets/openwebui.env" ];
      environments = {
        WEBUI_URL = "https://ai.home.5kw.li";
        ENABLE_OAUTH_SIGNUP = "true";
        OAUTH_MERGE_ACCOUNTS_BY_EMAIL = "true";
        OAUTH_CLIENT_ID = "HNcsNHmq~dNWJ-CPSPKzV-G4ifjsgTcTYhLcIpLE4lTCae_3YxXAOzGDN2BPWi-E";
        OPENID_PROVIDER_URL = "https://auth.home.5kw.li/.well-known/openid-configuration";
        OAUTH_PROVIDER_NAME = "Authelia";
        OAUTH_SCOPES = "openid email profile groups";
        ENABLE_OAUTH_ROLE_MANAGEMENT = "true";
        OAUTH_ALLOWED_ROLES = "openwebui,openwebui-admin";
        OAUTH_ADMIN_ROLES = "openwebui-admin";
        OAUTH_ROLES_CLAIM = "groups";
        # OPENID_REDIRECT_URI = "https://ai.home.5kw.li/oauth/oidc/callback";
      };
      # needed because oidc is on tailscale
      networks = [ "host" ];
    };
  };

  services.caddy.extraConfig = ''
    ai.home.5kw.li {
      reverse_proxy localhost:${toString 8080}
    }
  '';
}
