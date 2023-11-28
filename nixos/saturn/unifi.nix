{ config, ... }:
let
  unifiDir = "/var/lib/unifi";
  mongoDir = "/var/lib/mongo/4.4";
  mongoPort = "27017";
in
{
  users.users.unifi = {
    isSystemUser = true;
    group = "unifi";
  };
  users.groups.unifi = { };

  systemd.tmpfiles.rules = [
    "d ${unifiDir} 700 unifi unifi"
    "z ${unifiDir} 700 unifi unifi"
    "d ${mongoDir} 700 root root"
    "z ${mongoDir} 700 root root"
  ];

  virtualisation.oci-containers.containers = {
    unifi-mongo = {
      image = "docker.io/mongo:4.4";
      volumes = [
        "${mongoDir}:/data/db"
        "/var/secrets/mongo-unifi-init.js:/docker-entrypoint-initdb.d/init-mongo.js:ro"
      ];
      ports = [ "${mongoPort}:${mongoPort}" ];
      extraOptions = [ "--memory=512m" ];
    };
    unifi-controller = {
      image = "lscr.io/linuxserver/unifi-network-application:latest";
      environment = {
        PUID = toString config.users.users.unifi.uid;
        PGID = toString config.users.groups.unifi.gid;
        MEM_LIMIT = "512";
        MEM_STARTUP = "512";
        TZ = "Etc/Utc";
        MONGO_PORT = mongoPort;
        MONGO_HOST = "localhost";
        MONGO_DBNAME = "unifi";
        MONGO_USER = "unifi";
      };
      volumes = [
        "${unifiDir}:/config"
      ];
      extraOptions = [
        "--env-file=/var/secrets/unifi.env"
        "--memory=512m"
        "--label=io.containers.autoupdate=registry"
        "--network=host"
      ];
    };
  };

  networking.firewall = {
    # https://help.ubnt.com/hc/en-us/articles/218506997
    allowedTCPPorts = [
      8080 # Port for UAP to inform controller.
      8880 # Port for HTTP portal redirect, if guest portal is enabled.
      8843 # Port for HTTPS portal redirect, ditto.
      6789 # Port for UniFi mobile speed test.
    ];
    allowedUDPPorts = [
      3478 # UDP port used for STUN.
      10001 # UDP port used for device discovery.
    ];
  };

  services.caddy.extraConfig = ''
    unifi.home.5kw.li {
      reverse_proxy localhost:8443 {
        transport http {
          tls
          tls_insecure_skip_verify
        } 
      }
    }
  '';
}
