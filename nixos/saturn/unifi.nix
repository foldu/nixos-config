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
    ports = [
      "8443:8443"
      "3478:3478/udp"
      "10001:10001/udp"
      "8080:8080"
      # "1900:1900/udp"
      "8843:8843"
      "8880:8880"
      "6789:6789"
      "5514:5514/udp"
    ];
    extraOptions = [ "--memory=1g" ];
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
