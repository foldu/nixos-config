{ pkgs, ... }: {
  services.jellyfin.enable = true;

  services.caddy.extraConfig = ''
    jellyfin.nebula.5kw.li {
      reverse_proxy http://127.0.0.1:8096
    }
  '';
}
