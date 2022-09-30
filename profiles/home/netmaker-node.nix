{ pkgs, ... }: {
  environment.systemPackages = [
    pkgs.netmaker-netclient
  ];

  networking.wireguard.enable = true;

  systemd.services.netclient = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    description = "Netclient Daemon";
    documentation = [ "https://docs.netmaker.org https://k8s.netmaker.org" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.netmaker-netclient}/bin/netclient daemon";
      RestartSec = "15s";
    };
    wantedBy = [ "multi-user.target" ];
  };
}