{ pkgs, lib, ... }:
let
  settings = pkgs.callPackage ../../settings.nix { };
in
{
  home.packages =
    let
      pkgs =
        builtins.map (lib.attrByPath [ "pkg" ] null) (lib.attrValues settings.apps);
    in
    builtins.filter (pkg: pkg != null) pkgs;
  xdg = {
    enable = true;
    mimeApps =
      let
        desktopFile = lib.mapAttrs (_: v: v.desktopFile) settings.apps;
      in
      rec {
        enable = true;
        defaultApplications = {
          "image/bmp" = desktopFile.imageViewer;
          "image/png" = desktopFile.imageViewer;
          "image/jpeg" = desktopFile.imageViewer;
          "image/webp" = desktopFile.imageViewer;
          "image/gif" = desktopFile.imageViewer;
          "inode/directory" = desktopFile.fileBrowser;
          "text/html" = desktopFile.browser;
          "application/pdf" = desktopFile.pdfViewer;
          "application/x-bittorrent" = desktopFile.torrentClient;
          "x-scheme-handler/http" = desktopFile.browser;
          "x-scheme-handler/https" = desktopFile.browser;
          "x-scheme-handler/unknown" = desktopFile.browser;
          "x-scheme-handler/magnet" = desktopFile.torrentClient;
          "text/plain" = desktopFile.graphicalEditor;
          "x-scheme-handler/mailto" = desktopFile.emailClient;

          # help
          "video/x-ogm+ogg" = desktopFile.videoPlayer;
          "video/3gp" = desktopFile.videoPlayer;
          "video/3gpp" = desktopFile.videoPlayer;
          "video/3gpp2" = desktopFile.videoPlayer;
          "video/dv" = desktopFile.videoPlayer;
          "video/divx" = desktopFile.videoPlayer;
          "video/fli" = desktopFile.videoPlayer;
          "video/flv" = desktopFile.videoPlayer;
          "video/mp2t" = desktopFile.videoPlayer;
          "video/mp4" = desktopFile.videoPlayer;
          "video/mp4v-es" = desktopFile.videoPlayer;
          "video/mpeg" = desktopFile.videoPlayer;
          "video/mpeg-system" = desktopFile.videoPlayer;
          "video/msvideo" = desktopFile.videoPlayer;
          "video/ogg" = desktopFile.videoPlayer;
          "video/quicktime" = desktopFile.videoPlayer;
          "video/vivo" = desktopFile.videoPlayer;
          "video/vnd.divx" = desktopFile.videoPlayer;
          "video/vnd.mpegurl" = desktopFile.videoPlayer;
          "video/vnd.rn-realvideo" = desktopFile.videoPlayer;
          "video/vnd.vivo" = desktopFile.videoPlayer;
          "video/webm" = desktopFile.videoPlayer;
          "video/x-anim" = desktopFile.videoPlayer;
          "video/x-avi" = desktopFile.videoPlayer;
          "video/x-flc" = desktopFile.videoPlayer;
          "video/x-fli" = desktopFile.videoPlayer;
          "video/x-flic" = desktopFile.videoPlayer;
          "video/x-flv" = desktopFile.videoPlayer;
          "video/x-m4v" = desktopFile.videoPlayer;
          "video/x-matroska" = desktopFile.videoPlayer;
          "video/x-mjpeg" = desktopFile.videoPlayer;
          "video/x-mpeg" = desktopFile.videoPlayer;
          "video/x-mpeg2" = desktopFile.videoPlayer;
          "video/x-ms-asf" = desktopFile.videoPlayer;
          "video/x-ms-asf-plugin" = desktopFile.videoPlayer;
          "video/x-ms-asx" = desktopFile.videoPlayer;
          "video/x-msvideo" = desktopFile.videoPlayer;
          "video/x-ms-wm" = desktopFile.videoPlayer;
          "video/x-ms-wmv" = desktopFile.videoPlayer;
          "video/x-ms-wmx" = desktopFile.videoPlayer;
          "video/x-ms-wvx" = desktopFile.videoPlayer;
          "video/x-nsv" = desktopFile.videoPlayer;
          "video/x-theora" = desktopFile.videoPlayer;
          "video/x-theora+ogg" = desktopFile.videoPlayer;
          "video/x-totem-stream" = desktopFile.videoPlayer;
        };
        associations.added = defaultApplications;
      };
  };
}
