{ ... }:
let
  port = 3932;
in
{
  services.galene = {
    enable = false;
    httpPort = port;
    insecure = true;
  };

  services.caddy.extraConfig = ''
    mirko.5kw.li {
        encode zstd gzip
        reverse_proxy localhost:${toString port}
    }
  '';

  networking.firewall.allowedUDPPorts = [ 1194 ];
  networking.firewall.allowedTCPPorts = [ 1194 ];

  networking.firewall.allowedUDPPortRanges = [
    {
      from = 32768;
      to = 60999;
    }
  ];
}
