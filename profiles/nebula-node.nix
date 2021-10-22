{ pkgs, ... }: {
  services.nebula.networks.evil = {
    enable = true;
    key = "/var/secrets/nebula/key.key";
    cert = "/var/secrets/nebula/crt.crt";
    ca = "/var/secrets/nebula/ca.crt";
    firewall = {
      outbound = [
        {
          host = "any";
          port = "any";
          proto = "any";
        }
      ];
      inbound = [
        {
          host = "any";
          port = "any";
          proto = "icmp";
        }
      ];
    };
    lighthouses = [ "192.168.100.1" ];
    staticHostMap = {
      "192.168.100.1" = [ "135.181.39.89:4242" ];
    };
  };
}
