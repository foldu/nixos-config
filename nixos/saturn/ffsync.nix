{ pkgs, config, ... }:
{
  services.mysql.package = pkgs.mariadb;

  services.firefox-syncserver = {
    enable = false;
    secrets = "/var/secrets/ffsync.env";
    singleNode = {
      enable = true;
      hostname = "ffsync.home.5kw.li";
      url = "https://ffsync.home.5kw.li";
    };
  };

  services.caddy.extraConfig = ''
    ffsync.home.5kw.li {
      reverse_proxy http://127.0.0.1:${toString config.services.firefox-syncserver.settings.port}
    }
  '';
}
