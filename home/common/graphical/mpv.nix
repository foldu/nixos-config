{ pkgs, ... }: {
  programs.mpv = {
    enable = true;
    config = {
      profile = "gpu-hq";
      hwdec = "auto-safe";
      script-opts = "ytdl_hook-ytdl_path=${pkgs.yt-dlp}/bin/yt-dlp";
    };
  };

  home.packages = [
    pkgs.celluloid
  ];

  dconf.settings."io/github/celluloid-player/celluloid" = {
    mpv-config-enable = true;
    mpv-config-file = "file:///home/barnabas/.config/mpv/mpv.conf";
  };
}
