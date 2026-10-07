# The upstream AppImage ships two entry points: the GUI (`photocraft`, which is
# AppRun) and `photocraft-cli`. appimage-exec.sh can only ever run AppRun, so
# the FHS environment gets a small dispatcher instead, and the CLI is a wrapper
# around `$out/bin/photocraft` that flips PHOTOCRAFT_RUN.
{
  appimageTools,
  fetchurl,
  lib,
  makeWrapper,
  writeShellScript,
}:
let
  pname = "photocraft";
  version = "0.3.0";

  # Upstream also publishes an aarch64 AppImage. It is deliberately not
  # packaged: nix-update rewrites the hash of the one system it evaluates, so a
  # second architecture here would go stale after the first version bump (see
  # scripts/update.sh), and no aarch64 host in this repo runs desktops.
  appimage = fetchurl {
    url = "https://github.com/storytold/photocraft/releases/download/v${version}/${pname}-${version}-linux-x86_64.AppImage";
    hash = "sha256-KeMBH0mlLqJcj+QEJYpsX62wIJTbtAqITWnmuoCOYTY=";
  };

  contents = appimageTools.extract {
    inherit pname version;
    src = appimage;
  };

  runner = writeShellScript "${pname}-run" ''
    if [ "''${PHOTOCRAFT_RUN:-gui}" = cli ]; then
      export APPDIR=${contents}
      exec ${contents}/usr/bin/photocraft-cli "$@"
    fi
    exec ${appimageTools.appimage-exec}/bin/appimage-exec.sh -w ${contents} -- "$@"
  '';
in
appimageTools.wrapAppImage {
  inherit pname version;

  src = contents;
  # appimageTools.wrapType2 hands nix-update the versioned fetchurl through
  # passthru.src, which keeps its position in this file; wrapAppImage is given
  # an already-extracted tree instead, so do the same by hand or
  # `nix-update --flake photocraft` has no source to rewrite.
  passthru.src = appimage;
  runScript = "${runner}";

  nativeBuildInputs = [ makeWrapper ];

  extraInstallCommands = ''
    makeWrapper $out/bin/${pname} $out/bin/photocraft-cli --set PHOTOCRAFT_RUN cli

    install -Dm644 ${contents}/ai.storyteller.photocraft.desktop \
      $out/share/applications/ai.storyteller.photocraft.desktop
    install -Dm644 ${contents}/usr/share/mime/packages/ai.storyteller.photocraft.xml \
      $out/share/mime/packages/ai.storyteller.photocraft.xml
    install -Dm644 ${contents}/usr/share/metainfo/ai.storyteller.photocraft.metainfo.xml \
      $out/share/metainfo/ai.storyteller.photocraft.metainfo.xml
    mkdir -p $out/share/icons
    cp -r ${contents}/usr/share/icons/hicolor $out/share/icons/hicolor
  '';

  meta = {
    description = "Image editor for photos and layered PSD/PSB documents";
    homepage = "https://github.com/storytold/photocraft";
    license = with lib.licenses; [
      mit
      asl20
    ];
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
  };
}
