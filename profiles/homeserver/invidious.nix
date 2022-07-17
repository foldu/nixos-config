{ config, lib, pkgs, ... }: {
  services.invidious = {
    enable = true;
    domain = "invidious.home.5kw.li";
    port = 24325;
  };

  systemd.services.invidious.serviceConfig = {
    MemoryHigh = "256M";
    MemoryMax = "512M";
  };

  services.caddy.extraConfig = ''
    invidious.home.5kw.li {
      reverse_proxy localhost:${toString config.services.invidious.port}
    }
  '';
}
