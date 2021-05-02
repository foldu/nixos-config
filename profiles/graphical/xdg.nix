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
          };
          associations.added = defaultApplications;
        };
  };
}
