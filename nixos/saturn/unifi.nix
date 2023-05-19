{ config, ... }:
let
  unifiDir = "/var/lib/unifi";
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
  ];

  virtualisation.oci-containers.containers.unifi = {
    image = "lscr.io/linuxserver/unifi-controller:latest";
    environment = {
      PUID = toString config.users.users.unifi.uid;
      PGID = toString config.users.groups.unifi.gid;
      MEM_LIMIT = "1024";
      MEM_STARTUP = "1024";
      TZ = "Etc/Utc";
    };
    volumes = [
      "${unifiDir}:/config"
    ];
    extraOptions = [
      "--memory=1g"
      "--label=io.containers.autoupdate=registry"
      "--network=host"
      "--pull=newer"
    ];
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
