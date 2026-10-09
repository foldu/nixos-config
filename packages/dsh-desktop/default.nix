# A thin Electron window over the `dsh web` user service. The service owns the
# harness process and publishes the URL it serves in a runtime file (see
# home/common/graphical/dsh-desktop.nix); this app only displays it, so the
# whole program is main.js plus the waiting page it shows until the service
# answers.
{
  dsh,
  electron,
  lib,
  librsvg,
  makeWrapper,
  stdenv,
}:

stdenv.mkDerivation {
  pname = "dsh-desktop";
  version = "0.1.0";

  src = lib.cleanSource ./.;

  nativeBuildInputs = [
    librsvg
    makeWrapper
  ];
  buildInputs = [ electron ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/dsh-desktop
    install -m644 main.js package.json starting.html $out/share/dsh-desktop/

    # The harness mark, from the same frontend dist that serves it as the web
    # app's favicon. Upstream ships it twice: favicon.svg is the black glyph
    # for light surfaces, favicon-dark.svg the white one for dark. A launcher
    # icon cannot follow the theme, and this desktop is dark, so install the
    # dark-surface variant at every size a taskbar may ask for.
    icon_svg=${dsh}/lib/node_modules/@deepseek-ai/dsh/node_modules/@deepseek-ai/dsh-web-frontend/dist/favicon-dark.svg
    for size in 16 32 48 64 128 256; do
      install -d $out/share/icons/hicolor/''${size}x''${size}/apps
      rsvg-convert -w "$size" -h "$size" \
        -o $out/share/icons/hicolor/''${size}x''${size}/apps/dsh-desktop.png "$icon_svg"
    done
    install -Dm644 "$icon_svg" $out/share/icons/hicolor/scalable/apps/dsh-desktop.svg
    # the same art beside the app for main.js's window-level icon option
    install -m644 $out/share/icons/hicolor/256x256/apps/dsh-desktop.png \
      $out/share/dsh-desktop/icon.png

    # Same opt-in as the browser wrappers: only take the Wayland path when the
    # session asked for it, so an X11 session still gets X11.
    makeWrapper ${lib.getExe electron} $out/bin/dsh-desktop \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-wayland-ime=true}}" \
      --add-flags "$out/share/dsh-desktop"

    install -Dm644 dsh-desktop.desktop $out/share/applications/dsh-desktop.desktop

    runHook postInstall
  '';

  meta = {
    description = "DeepSeek Harness web GUI in its own window";
    mainProgram = "dsh-desktop";
  };
}
