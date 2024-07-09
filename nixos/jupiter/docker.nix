{ pkgs, ... }:
{

  boot.enableContainers = false;

  virtualisation.docker = {
    enable = true;
    extraOptions = "--max-concurrent-downloads 1";
  };

  environment.systemPackages = [ pkgs.docker-compose ];
}
