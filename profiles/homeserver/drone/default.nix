{ config, lib, pkgs, ... }: {
  services.drone-server = {
    enable = true;
    host = "drone.5kw.li";
    proto = "https";
    adminName = "foldu";
    environmentFile = "/var/secrets/drone_server.env";
  };

  services.caddy.config = ''
    drone.5kw.li {
      reverse_proxy http://localhost:${toString config.services.drone-server.port}
    }
  '';

  users.users.${config.services.drone-server.user} = {
    extraGroups = [ "secrets" ];
  };

  services.drone-exec-runner = {
    enable = true;
  };

  users.users.${config.services.drone-exec-runner.user} = {
    extraGroups = [ "secrets" ];
  };
}
