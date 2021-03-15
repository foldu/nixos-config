{ pkgs, ... }:
{
  home-manager.users.barnabas.home.packages = with pkgs; [
    dolphin
    # all this stuff is needed for thumbnails to work in dolphin
    libsForQt5.kdegraphics-thumbnailers
    libsForQt5.kdialog
    libsForQt5.kio-extras
    libsForQt5.dolphin-plugins
    libsForQt5.ffmpegthumbs
  ];
}
