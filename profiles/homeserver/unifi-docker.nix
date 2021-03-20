{ config, lib, pkgs, ... }: {
  # FIXME: don't hardcode this
  users.groups.unifi.gid = 1200;
  users.users.unifi.uid = 1200;

  virtualisation.oci-containers.containers = {
    unifi = {
      image = "jacobalberty/unifi:stable";
      environment = {
        TZ = "Europe/Amsterdam";
        RUNAS_UID0 = "false";
        UNIFI_UID = "1200";
        UNIFI_GID = "1200";
      };
      volumes = [
        # FIXME: move this to a better directory
        "/srv/media/main/services/unifi:/unifi"
      ];
      extraOptions = [
        "--net=host"
        # JAVA thinks it's acceptable to eat all my RAMz
        # so starve it prematurely
        "--memory=512M"
      ];
    };
  };
}
