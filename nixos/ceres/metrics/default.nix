{
  pkgs,
  home-network,
  lib,
  config,
  outputs,
  ...
}:
{
  imports = [ ../../common/alertmanager ];

  services.prometheus = {
    enable = true;
    webExternalUrl = "https://prometheus-backup.home.5kw.li";
    ruleFiles = [
      (pkgs.writeText "prometheus-rules.yml" (
        builtins.toJSON {
          groups = [
            {
              name = "ceres-alerts";
              rules = outputs.lib.mkPrometheusRules (import ./alerts.nix { inherit lib; });
            }
          ];
        }
      ))
    ];
    scrapeConfigs = [
      {
        job_name = "telegraf";
        scrape_interval = "60s";
        metrics_path = "/metrics";
        static_configs = [
          {
            targets = [
              "localhost:9273"
              "saturn.home.5kw.li:9273"
            ];
            labels.type = "server";
          }
        ];
      }
    ];
    alertmanagers = [ { static_configs = [ { targets = [ "localhost:9093" ]; } ]; } ];
  };

  services.telegraf.extraConfig.inputs.net_response = [
    {
      protocol = "tcp";
      address = "${home-network.devices.saturn.ip}:22";
      send = "SSH-2.0-Telegraf";
      expect = "SSH-2.0";
      tags.host = "saturn";
      timeout = "10s";
    }
  ];

  services.prometheus.alertmanager.webExternalUrl = "https://alertmanager-backup.home.5kw.li";

  services.caddy.extraConfig = ''
    prometheus-backup.home.5kw.li {
        reverse_proxy localhost:${toString config.services.prometheus.port}
    }

    alertmanager-backup.home.5kw.li {
        reverse_proxy localhost:${toString config.services.prometheus.alertmanager.port}
    }
  '';
}
