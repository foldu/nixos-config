{ config, lib, pkgs, ... }: {
  services.gitea = {
    enable = true;
    domain = "git.home.5kw.li";
    rootUrl = "https://git.home.5kw.li";
    httpPort = 3032;
    settings = {
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
  networking.firewall.allowedTCPPorts = [ config.services.gitea.httpPort ];

  services.caddy.extraConfig = ''
    git.home.5kw.li {
      reverse_proxy localhost:${toString config.services.gitea.httpPort}
    }
  '';
}
