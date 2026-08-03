{ ... }:
let
  domain = "netbird.5kw.li";
  dashboardPort = toString 8890;
  managementPort = toString 8891;
  stunPort = toString 3478;
  netbirdConfig = {
    server = {
      listenAddress = ":80";
      exposedAddress = "https://netbird.5kw.li:443";
      stunPorts = [ 3478 ];
      metricsPort = [ 9090 ];
      healthcheckAddress = ":9000";
      logLevel = "info";
      logFile = "console";

      #authSecret: ""
      dataDir = "/var/lib/netbird";

      auth = {
        issuer = "https://netbird.5kw.li/oauth2";
        signKeyRefreshEnabled = true;
        dashboardRedirectURIs = [
          "https://netbird.5kw.li/nb-auth"
          "https://netbird.5kw.li/nb-silent-auth"
        ];
        cliRedirectURIs = [ "http://localhost:53000/" ];
      };

      reverseProxy = {
        trustedHTTPProxies = [ "172.30.0.10/32" ];
      };
      store = {
        engine = "sqlite";
        #encryptionKey: ""
      };
    };
  };
  netbirdDashboardConfig = {
    NETBIRD_MGMT_API_ENDPOINT = "https://netbird.5kw.li";
    NETBIRD_MGMT_GRPC_API_ENDPOINT = "https://netbird.5kw.li";
    # OIDC - using embedded IdP
    AUTH_AUDIENCE = "netbird-dashboard";
    AUTH_CLIENT_ID = "netbird-dashboard";
    AUTH_CLIENT_SECRET = "";
    AUTH_AUTHORITY = "https://netbird.5kw.li/oauth2";
    USE_AUTH0 = "false";
    AUTH_SUPPORTED_SCOPES = "openid profile email groups";
    AUTH_REDIRECT_URI = "/nb-auth";
    AUTH_SILENT_REDIRECT_URI = "/nb-silent-auth";
    # SSL
    NGINX_SSL_PORT = "443";
    # Letsencrypt
    LETSENCRYPT_DOMAIN = "none";
  };
in
{
  virtualisation.quadlet.containers = {
    netbird-dashboard.containerConfig = {
      image = "docker.io/netbirdio/dashboard:latest";
      environmentFiles = [ "/var/secrets/netbird_dashboard.env" ];
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
        "${stunPort}:${stunPort}/udp"
      ];
      volumes = [
        "netbird_data:/var/lib/netbird"
        "/var/secrets/netbird_config.yaml:/etc/netbird/config.yaml"
      ];
      autoUpdate = "registry";
    };
  };

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
