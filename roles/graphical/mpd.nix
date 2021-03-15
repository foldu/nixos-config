{ config, lib, pkgs, ... }: {
  services.mpd = {
    enable = true;
    musicDirectory = "/run/media/music";
    dataDir = "${config.xdg.dataHome}/mpd";
    extraConfig = ''
      audio_output {
        type "pulse"
        name "mpd"
      }
    '';
  };

  services.mpdris2.enable = true;

  home.packages = [
    pkgs.ncmpcpp
  ];

  xdg.configFile."ncmpcpp" = {
    source = ../../config/ncmpcpp;
    recursive = true;
  };
}
