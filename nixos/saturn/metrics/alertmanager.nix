{ config, ... }: {
  services.prometheus.alertmanager = {
    enable = true;
    environmentFile = "/var/secrets/alertmanager.env";
    webExternalUrl = "https://alertmanager.home.5kw.li";
    # listenAddress = "[::1]";
    checkConfig = false;
    configText = builtins.readFile ./alertmanager.yml;
  };

  services.caddy.extraConfig = ''
    alertmanager.home.5kw.li {
        reverse_proxy localhost:${toString config.services.prometheus.alertmanager.port}
    }
  '';
}
