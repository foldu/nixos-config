{ ... }:
let
  port = "9845";
  db_dir = "/db";
in
{
  # NOTE: volumes eat my data for some reason
  virtualisation.quadlet = {
    containers.img-bookmark = {
      containerConfig = {
        image = "container-registry.home.5kw.li/foldu/img-bookmark:latest";
        environments = {
          IMG_BOOKMARK_PORT = port;
          IMG_BOOKMARK_DBDIR = db_dir;
        };
        volumes = [
          "/var/lib/img-bookmark/db:${db_dir}"
        ];
        publishPorts = [
          "127.0.0.1:${port}:${port}"
        ];
        autoUpdate = "registry";
      };
    };
  };

  services.caddy.extraConfig = ''
    img-bookmark.home.5kw.li {
      reverse_proxy localhost:${port}
    }
  '';

}
