{ ... }:
{
  services.prometheus.alertmanager = {
    enable = true;
    environmentFile = "/var/secrets/alertmanager.env";
    # listenAddress = "[::1]";
    checkConfig = false;
    configText = builtins.readFile ./alertmanager.yml;
  };
}
