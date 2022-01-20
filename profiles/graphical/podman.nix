{ pkgs, ... }: {
  virtualisation.podman.enable = true;
  environment.systemPackages = [ pkgs.podman-compose ];
}
