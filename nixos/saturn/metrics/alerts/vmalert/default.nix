{
  config,
  pkgs,
  lib,
  ...
}:
let
  vmalertDir = "/var/lib/vmalert";
in
{
  users.users.vmalert = {
    isSystemUser = true;
    group = "vmalert";
  };

  users.groups.vmalert = { };

  systemd.tmpfiles.rules = [
    "d ${vmalertDir} 700 vmalert vmalert"
    "z ${vmalertDir} 700 vmalert vmalert"
  ];

  systemd.services.vmalert = {
    enable = true;
    description = "Victoriametrics alerting";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = lib.strings.concatStringsSep " " [
        "${pkgs.victoriametrics}/bin/vmalert"
        "-rule=${./vmalert.rules.yml}"
        "-envflag.enable"
        "-datasource.url=https://metrics.home.5kw.li"
        "-notifier.url=http://127.0.0.1:${toString config.services.prometheus.alertmanager.port}"
        "-remoteWrite.url=https://metrics.home.5kw.li"
        "-remoteRead.url=https://metrics.home.5kw.li"
        "-external.url=https://metrics.home.5kw.li"
      ];
      EnvironmentFile = "/var/secrets/vmalert.env";
      User = "vmalert";
      Group = "vmalert";
      WorkingDirectory = vmalertDir;
    };
  };
}
