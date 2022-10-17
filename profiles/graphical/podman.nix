{ pkgs, ... }: {
  virtualisation.docker = {
    # this first world shithole does not have internet
    # and concurrent downloads cause docker to timeout
    extraOptions = "--max-concurrent-downloads 1";
    enable = true;
  };
  environment.systemPackages = [ pkgs.docker-compose ];
}
