{ pkgs, ... }: {
  services.resolved = {
    enable = true;
    dnssec = "false";
    fallbackDns = [ "1.1.1.1" "1.0.0.1" "9.9.9.9" ];
  };

  systemd.services."netmaker-resolve" = {
    enable = true;
    after = [ "netclient.service" ];
    partOf = [ "netclient.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "simple";
    path = [ pkgs.iproute2 pkgs.bash ];
    script = "${./netmaker-resolve.sh}";
  };
}
