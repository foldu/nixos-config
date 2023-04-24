{ config, ... }: {
  services.gitea = {
    enable = true;
    settings = {
      server = {
        ROOT_URL = "https://git.home.5kw.li";
        HTTP_PORT = 3032;
        DOMAIN = "git.home.5kw.li";
      };
      service = {
        DISABLE_REGISTRATION = true;
      };
      picture = {
        DISABLE_GRAVATAR = true;
        ENABLE_FEDERATED_AVATAR = false;
      };
    };
    dump.enable = true;
  };

  # FIXME:
  networking.firewall.allowedTCPPorts = [ config.services.gitea.settings.server.HTTP_PORT ];

  services.caddy.extraConfig = ''
    git.home.5kw.li {
      reverse_proxy localhost:${toString config.services.gitea.settings.server.HTTP_PORT}
    }
  '';
}
