{ config, lib, pkgs, ... }:

let
  config = pkgs.writeText "mpv.conf" ''
    profile=gpu-hq
    ytdl-format=bestvideo[height<=?1080]+bestaudio/best
  '';
in
{
  home.packages = [
    pkgs.celluloid
  ];

  dconf.enable = true;
  dconf.settings = {
    "io/github/celluloid-player/celluloid" = {
      mpv-config-enable = true;
      mpv-config-file = "${config}";
    };
  };
}
