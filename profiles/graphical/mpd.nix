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
      audio_output {
        type                    "fifo"
        name                    "mpd_fifo"
        path                    "/run/user/1000/mpd.fifo"
        format                  "44100:16:2"
      }
    '';
  };

  services.mpdris2.enable = true;

  home.packages = [
    (pkgs.ncmpcpp.override {
      visualizerSupport = true;
    })
  ];

  xdg.configFile."ncmpcpp" = {
    source = ../../config/ncmpcpp;
    recursive = true;
  };
}
