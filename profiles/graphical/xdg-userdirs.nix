{ pkgs, ... }:
{
  xdg.userDirs = {
    enable = true;
    desktop = "\$HOME";
    documents = "\$HOME/doc";
    download = "\$HOME/downloads";
    pictures = "\$HOME/img";
    music = "/run/media/music";
    videos = "/run/media/videos";
  };
}
