{ ... }:
let
  port = 9348;
in
{
  virtualisation.quadlet.containers.bambuddy = {
    containerConfig = {
      image = "ghcr.io/maziggy/bambuddy:latest";
      volumes = [
        "/var/lib/bambuddy/data:/app/data"
        "/var/lib/bambuddy/logs:/app/logs"
      ];
      environments = {
        TZ = "Europe/Amsterdam";
        PUID = "1000";
        PGID = "100";
        PORT = toString port;
      };
      networks = [ "host" ];
      addCapabilities = [ "NET_BIND_SERVICE" ];
      autoUpdate = "registry";
    };
  };

  services.caddy.extraConfig = ''
    bambu.home.5kw.li {
      reverse_proxy localhost:${toString port}
    }
  '';
}
