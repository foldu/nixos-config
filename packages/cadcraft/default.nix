# The upstream AppImage ships two entry points: the GUI (`cadcraft`, which is
# AppRun) and `cadcraft-cli`. appimage-exec.sh can only ever run AppRun, so the
# FHS environment gets a small dispatcher instead, and the CLI is a wrapper
# around `$out/bin/cadcraft` that flips CADCRAFT_RUN.
{
  appimageTools,
  fetchurl,
  lib,
  makeWrapper,
  writeShellScript,
}:
let
  pname = "cadcraft";
  version = "0.3.0";

  # Upstream also publishes an aarch64 AppImage. Like photocraft it is
  # deliberately not packaged: nix-update rewrites the hash of the one system it
  # evaluates, so a second architecture here would go stale after the first
  # version bump (see scripts/update.sh), and no aarch64 host in this repo runs
  # desktops.
  appimage = fetchurl {
    url = "https://github.com/storytold/${pname}/releases/download/v${version}/${pname}-${version}-linux-x86_64.AppImage";
    hash = "sha256-tGPweKEi+eTqV8N8XkPsOa7AAkHWoJVo739XO3MnmX8=";
  };

  contents = appimageTools.extract {
    inherit pname version;
    src = appimage;
  };

  runner = writeShellScript "${pname}-run" ''
    if [ "''${CADCRAFT_RUN:-gui}" = cli ]; then
      export APPDIR=${contents}
      exec ${contents}/usr/bin/cadcraft-cli "$@"
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
  # `nix-update --flake cadcraft` has no source to rewrite.
  passthru.src = appimage;

  runScript = "${runner}";

  nativeBuildInputs = [ makeWrapper ];

  extraInstallCommands = ''
    makeWrapper $out/bin/${pname} $out/bin/cadcraft-cli --set CADCRAFT_RUN cli

    install -Dm644 ${contents}/ai.storyteller.cadcraft.desktop \
      $out/share/applications/ai.storyteller.cadcraft.desktop
    install -Dm644 ${contents}/usr/share/mime/packages/ai.storyteller.cadcraft.xml \
      $out/share/mime/packages/ai.storyteller.cadcraft.xml
    install -Dm644 ${contents}/usr/share/metainfo/ai.storyteller.cadcraft.metainfo.xml \
      $out/share/metainfo/ai.storyteller.cadcraft.metainfo.xml
    mkdir -p $out/share/icons
    cp -r ${contents}/usr/share/icons/hicolor $out/share/icons/hicolor
  '';

  meta = {
    description = "Computer-aided design and drafting; opens and saves DXF and DWG drawings";
    homepage = "https://github.com/storytold/cadcraft";
    license = with lib.licenses; [
      mit
      asl20
    ];
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
  };
}
