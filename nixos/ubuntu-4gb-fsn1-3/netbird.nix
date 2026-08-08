{ config, ... }:
let
  domain = "netbird.5kw.li";
  dashboardPort = toString 8890;
  managementPort = toString 8891;
  stunPort = 3478;
in
{
  virtualisation.quadlet.containers = {
    netbird-dashboard.containerConfig = {
      image = "docker.io/netbirdio/dashboard:latest";
      environmentFiles = [ config.sops.secrets."netbird/dashboard/env".path ];
      publishPorts = [
        "127.0.0.1:${dashboardPort}:80"
      ];
      autoUpdate = "registry";
    };
    netbird-server.containerConfig = {
      image = "docker.io/netbirdio/netbird-server:latest";
      # contains NETBIRD_STORAGE_ENCRYPTION_KEY and NETBIRD_AUTH_SECRET
      # environmentFiles = [ "/var/secrets/netbird.env" ];
      exec = [
        "--config"
        "/etc/netbird/config.yaml"
      ];
      publishPorts = [
        "127.0.0.1:${managementPort}:80"
        "${toString stunPort}:${toString stunPort}/udp"
      ];
      volumes = [
        "netbird_data:/var/lib/netbird"
        "${config.sops.secrets."netbird/config_yaml".path}:/etc/netbird/config.yaml"
      ];
      autoUpdate = "registry";
    };
  };

  sops.secrets = {
    "netbird/config_yaml" = { };
    "netbird/dashboard/env" = { };
  };

  # STUN/TURN for direct peer connections
  networking.firewall.allowedUDPPorts = [ stunPort ];

  services.caddy.virtualHosts.${domain}.extraConfig = ''
    # Native gRPC (needs HTTP/2 cleartext to backend)
    @grpc header Content-Type application/grpc*
    reverse_proxy @grpc h2c://127.0.0.1:${managementPort}

    # Combined server paths (relay, signal, management, OAuth2)
    @backend path /relay* /ws-proxy/* /api/* /oauth2/*
    reverse_proxy @backend 127.0.0.1:${managementPort}

    # Dashboard (everything else)
    reverse_proxy /* 127.0.0.1:${dashboardPort}
  '';

}
