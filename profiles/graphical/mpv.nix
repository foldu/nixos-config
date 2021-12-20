{ pkgs, ... }: {
  programs.mpv = {
    enable = true;
    config = {
      profile = "gpu-hq";
      hwdec = "auto-safe";
      script-opts = "ytdl_hook-ytdl_path=${pkgs.yt-dlp}/bin/yt-dlp";
    };
  };
}
