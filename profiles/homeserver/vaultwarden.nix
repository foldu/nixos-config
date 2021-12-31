{ config, lib, pkgs, ... }: {
  services.vaultwarden = {
    enable = true;
    config = {
      rocketPort = 4000;
      websocketPort = 4001;
      websocketEnabled = true;
    };
  };

  services.caddy.extraConfig = ''
    vaultwarden.nebula.5kw.li {
      header {
        # Enable cross-site filter (XSS) and tell browser to block detected attacks
        X-XSS-Protection "1; mode=block"
        # Disallow the site to be rendered within a frame (clickjacking protection)
        X-Frame-Options "DENY"
        # Prevent search engines from indexing (optional)
        X-Robots-Tag "none"
        # Server name removing
        -Server
      }

      # The negotiation endpoint is also proxied to Rocket
      reverse_proxy /notifications/hub/negotiate localhost:${toString config.services.vaultwarden.config.rocketPort}

      # Notifications redirected to the websockets server
      reverse_proxy /notifications/hub localhost:${toString config.services.vaultwarden.config.websocketPort}

       # Proxy the Root directory to Rocket
      reverse_proxy localhost:${toString config.services.vaultwarden.config.rocketPort}
    }
  '';
}
