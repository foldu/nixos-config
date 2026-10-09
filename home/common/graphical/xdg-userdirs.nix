{ config, ... }:
{
  xdg.userDirs = {
    enable = true;
    desktop = "${config.home.homeDirectory}";
    documents = "${config.home.homeDirectory}/doc";
    download = "${config.home.homeDirectory}/downloads";
    pictures = "${config.home.homeDirectory}/img";
    music = "/run/media/barnabas/music";
    videos = "${config.home.homeDirectory}/videos";
    setSessionVariables = true;
  };
}
