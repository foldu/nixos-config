{ pkgs, config, ... }: {
  # services.unifi = {
  #   enable = true;
  #   openFirewall = true;
  #   maximumJavaHeapSize = 1024;
  #   unifiPackage = pkgs.unifi;
  # };

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
