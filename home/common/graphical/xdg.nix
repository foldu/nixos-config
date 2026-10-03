{
  pkgs,
  lib,
  getSettings,
  ...
}:
let
  settings = getSettings pkgs;

  # settings key -> desktop file id, e.g. graphicalEditor -> "dev.zed.Zed.desktop"
  desktopFile = lib.mapAttrs (_: v: v.desktopFile) settings.apps;

  # ---------------------------------------------------------------------------
  # Why this file computes a few hundred MIME defaults instead of just listing
  # the handful of types we actually care about.
  #
  # Symptom: opening a .nix, .py, .rs, .json, .sh, ... file launched Firefox
  # instead of Zed.
  #
  # Cause: the XDG mimeapps format has no wildcards. `[Default Applications]`
  # is a map of *exact* MIME type -> desktop file, and every consumer matches
  # exactly: xdg-mime's check_mimeapps_list greps `^$MIME=`, GIO hashes the
  # type, and mimeinfo.cache/defaults.list work the same way. There is no way
  # to write `text/*`. Zed's own .desktop file only advertises
  # `text/plain;application/x-zerosize;x-scheme-handler/zed`, so a default on
  # `text/plain` does not extend to `text/x-nix` or any other subtype either.
  #
  # What happens without a rule: `xdg-open` (which is what niri keybindings,
  # DMS and anything else shelling out actually use) looks up the type, finds
  # no default, then no mailcap/mimeopen handler, and finally falls through to
  # its hardcoded last-resort list in /run/current-system/sw/bin/xdg-open:
  #
  #     BROWSER=x-www-browser:firefox:iceweasel:seamonkey:mozilla:epiphany:...
  #
  # BROWSER is unset here, so that is literally "launch the first browser on
  # PATH", i.e. Firefox, with the file as an argument. GIO-based openers
  # (`gio open`, Nautilus) also resolve handlers through the MIME *supertype*
  # graph, which is why they mostly landed on Zed already and why the behaviour
  # looked inconsistent; xdg-open does not, hence the split brain.
  #
  # Fix: don't hand-write the type list. shared-mime-info already ships the
  # hierarchy that `text/*` implies as a flat `child parent` file in
  # `$out/share/mime/subclasses`, and `text/plain` is the root of every text
  # type the system knows. Notably that includes application/json,
  # application/toml, application/yaml and, through application/xml, all the
  # XML-derived types such as .ts/.tsx/.xhtml which browsers claim via
  # `text/xml`. So take the transitive closure of `text/plain` and emit one
  # exact default per type: one rule in the source, ~300 entries in
  # mimeapps.list.
  #
  # Caveats, so nobody is surprised later:
  #  * This reads a file out of a derivation during evaluation (import from
  #    derivation). shared-mime-info is small, cached and already a dependency
  #    of GTK, but it does break under --no-allow-import-from-derivation.
  #  * The text/plain closure is wider than `text/*`: it contains images
  #    (svg/eps), office formats, playlists and mail files. The ones we do not
  #    want in the editor are listed in nonEditorMimes and left untouched, so
  #    they keep whatever handler the distro recommends today.
  #  * It is narrower too: a few script types are not modelled as children of
  #    text/plain, hence alsoEditorMimes.
  #  * This makes the editor win over the distro recommendation for ~300 types.
  #    If a type behaves surprisingly, the fix is to add it to nonEditorMimes
  #    (keep the distro default) or to the explicit table below.
  # ---------------------------------------------------------------------------

  mimeDb = "${pkgs.shared-mime-info}/share/mime";

  # "child parent" pairs, e.g. "text/x-python text/plain"
  subclassPairs = map (lib.splitString " ") (
    lib.filter (s: s != "") (lib.splitString "\n" (builtins.readFile "${mimeDb}/subclasses"))
  );

  # invert to parent -> [ children ]
  mimeChildren = lib.foldl' (
    acc: pair:
    let
      child = builtins.elemAt pair 0;
      parent = builtins.elemAt pair 1;
    in
    acc // { ${parent} = (acc.${parent} or [ ]) ++ [ child ]; }
  ) { } (builtins.filter (p: builtins.length p == 2) subclassPairs);

  # everything that is, directly or transitively, sub-class-of text/plain
  textMimes = lib.converge (
    acc: lib.unique (acc ++ lib.concatMap (t: mimeChildren.${t} or [ ]) acc)
  ) [ "text/plain" ];

  # Text according to the MIME db, but we want the existing handler (browser,
  # LibreOffice, GIMP, Evince, Celluloid, Thunderbird, ...) to keep them.
  nonEditorMimes = [
    "text/html"
    "text/csv"
    "text/tab-separated-values"
    "application/postscript"
    "application/rtf"
    "image/svg+xml"
    "image/x-eps"
    "audio/x-mpegurl"
    "video/vnd.mpegurl"
    "application/vnd.apple.mpegurl"
    "application/vnd.oasis.opendocument.text-flat-xml"
    "application/vnd.oasis.opendocument.spreadsheet-flat-xml"
    "application/vnd.oasis.opendocument.presentation-flat-xml"
    "application/vnd.oasis.opendocument.graphics-flat-xml"

    # Mail. These live under text/plain too, and several of them currently have
    # no handler at all, which means they fall into the xdg-open browser hole.
    "message/rfc822"
    "message/news"
    "message/partial"
    "message/delivery-status"
    "message/disposition-notification"

    # Not actually text despite the text/ prefix.
    "text/x-devicetree-binary"
    "text/jscript.encode"
    "text/x-imelody"
  ];

  # Source/script types that shared-mime-info does not model as descendants of
  # text/plain, so the closure above misses them.
  alsoEditorMimes = [
    "application/x-zerosize"
    "inode/x-empty"
    "text/x-awk"
    "text/x-csh"
    "text/x-gawk"
    "text/x-gradle"
    "text/x-nawk"
    "text/x-sed"
    "text/x-shellscript"
  ];
in
{
  home.packages =
    let
      pkgs = map (lib.attrByPath [ "pkg" ] null) (lib.attrValues settings.apps);
    in
    builtins.filter (pkg: pkg != null) pkgs;
  xdg = {
    enable = true;
    mimeApps = rec {
      enable = true;
      defaultApplications =
        # Everything shared-mime-info considers text, minus the exclusions,
        # goes to the editor.
        lib.genAttrs (lib.subtractLists nonEditorMimes textMimes) (_: desktopFile.graphicalEditor)
        // lib.genAttrs alsoEditorMimes (_: desktopFile.graphicalEditor)
        // {
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
          "message/rfc822" = desktopFile.emailClient;
          "message/news" = desktopFile.emailClient;
          "message/partial" = desktopFile.emailClient;
          "message/delivery-status" = desktopFile.emailClient;
          "message/disposition-notification" = desktopFile.emailClient;

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
