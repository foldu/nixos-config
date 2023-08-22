{ pkgs, lib, config, ... }: {
  imports = [
    ./alertmanager.nix
    ./telegraf-inputs/saturn.nix
  ];

  services.prometheus = {
    enable = true;
    webExternalUrl = "https://prometheus.home.5kw.li";
    ruleFiles = [
      (pkgs.writeText "prometheus-rules.yml" (builtins.toJSON {
        groups = [
          {
            name = "generic-alerts";
            rules = import ./alerts/generic.nix { inherit lib; };
          }
        ];
      }))
    ];
    scrapeConfigs = [
      {
        job_name = "telegraf";
        scrape_interval = "60s";
        metrics_path = "/metrics";
        static_configs = [
          {
            targets = [
              "saturn.home.5kw.li:9273"
              "ceres.home.5kw.li:9273"
            ];
            labels.type = "server";
          }
          {
            targets = [
              "jupiter.home.5kw.li:9273"
              "mars.home.5kw.li:9273"
            ];
            labels.type = "pc";
          }
        ];
      }
      # {
      #   job_name = "caddy";
      #   scrape_interval = "60s";
      #   # metrics_path = "/metrics";
      #   static_configs = [
      #     {
      #       targets = [
      #         "localhost:2019"
      #       ];
      #     }
      #   ];
      # }
      {
        job_name = "gitea";
        scrape_interval = "60s";
        metrics_path = "/metrics";
        scheme = "https";
        static_configs = [
          {
            targets = [
              "git.home.5kw.li:443"
            ];
          }
        ];
      }
    ];
    alertmanagers = [
      {
        static_configs = [
          {
            targets = [ "localhost:9093" ];
          }
        ];
      }
    ];
  };

  services.caddy.extraConfig = ''
    prometheus.home.5kw.li {
        reverse_proxy localhost:${toString config.services.prometheus.port}
    }
  '';
}
