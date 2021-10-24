{ pkgs, config, lib, ... }: {
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
      inbound =
        let
          bridgePorts = proto: builtins.map
            (port:
              {
                inherit proto;
                port = toString port;
                host = "any";
                groups = [ "home" ];
              });
        in
        [
          {
            host = "any";
            port = "any";
            proto = "icmp";
          }
          {
            groups = [ "home" ];
            port = "22";
            proto = "tcp";
          }
        ]
        ++ bridgePorts "tcp" config.networking.firewall.allowedTCPPorts
        ++ bridgePorts "udp" config.networking.firewall.allowedUDPPorts;
    };
    lighthouses = [ "192.168.100.1" ];
    staticHostMap = {
      "192.168.100.1" = [ "135.181.39.89:4242" ];
    };
  };
}
