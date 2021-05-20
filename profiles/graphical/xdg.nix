{ pkgs, lib, ... }:
let
  settings = pkgs.callPackage ../../settings.nix {};
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

            # help
            "video/x-ogm+ogg" = desktopFiles.videoPlayer;
            "video/3gp" = desktopFiles.videoPlayer;
            "video/3gpp" = desktopFiles.videoPlayer;
            "video/3gpp2" = desktopFiles.videoPlayer;
            "video/dv" = desktopFiles.videoPlayer;
            "video/divx" = desktopFiles.videoPlayer;
            "video/fli" = desktopFiles.videoPlayer;
            "video/flv" = desktopFiles.videoPlayer;
            "video/mp2t" = desktopFiles.videoPlayer;
            "video/mp4" = desktopFiles.videoPlayer;
            "video/mp4v-es" = desktopFiles.videoPlayer;
            "video/mpeg" = desktopFiles.videoPlayer;
            "video/mpeg-system" = desktopFiles.videoPlayer;
            "video/msvideo" = desktopFiles.videoPlayer;
            "video/ogg" = desktopFiles.videoPlayer;
            "video/quicktime" = desktopFiles.videoPlayer;
            "video/vivo" = desktopFiles.videoPlayer;
            "video/vnd.divx" = desktopFiles.videoPlayer;
            "video/vnd.mpegurl" = desktopFiles.videoPlayer;
            "video/vnd.rn-realvideo" = desktopFiles.videoPlayer;
            "video/vnd.vivo" = desktopFiles.videoPlayer;
            "video/webm" = desktopFiles.videoPlayer;
            "video/x-anim" = desktopFiles.videoPlayer;
            "video/x-avi" = desktopFiles.videoPlayer;
            "video/x-flc" = desktopFiles.videoPlayer;
            "video/x-fli" = desktopFiles.videoPlayer;
            "video/x-flic" = desktopFiles.videoPlayer;
            "video/x-flv" = desktopFiles.videoPlayer;
            "video/x-m4v" = desktopFiles.videoPlayer;
            "video/x-matroska" = desktopFiles.videoPlayer;
            "video/x-mjpeg" = desktopFiles.videoPlayer;
            "video/x-mpeg" = desktopFiles.videoPlayer;
            "video/x-mpeg2" = desktopFiles.videoPlayer;
            "video/x-ms-asf" = desktopFiles.videoPlayer;
            "video/x-ms-asf-plugin" = desktopFiles.videoPlayer;
            "video/x-ms-asx" = desktopFiles.videoPlayer;
            "video/x-msvideo" = desktopFiles.videoPlayer;
            "video/x-ms-wm" = desktopFiles.videoPlayer;
            "video/x-ms-wmv" = desktopFiles.videoPlayer;
            "video/x-ms-wmx" = desktopFiles.videoPlayer;
            "video/x-ms-wvx" = desktopFiles.videoPlayer;
            "video/x-nsv" = desktopFiles.videoPlayer;
            "video/x-theora" = desktopFiles.videoPlayer;
            "video/x-theora+ogg" = desktopFiles.videoPlayer;
            "video/x-totem-stream" = desktopFiles.videoPlayer;
          };
          associations.added = defaultApplications;
        };
  };
}
