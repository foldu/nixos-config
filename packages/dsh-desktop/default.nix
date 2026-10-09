# A thin Electron window over the `dsh web` user service. The service owns the
# harness process and publishes the URL it serves in a runtime file (see
# home/common/graphical/dsh-desktop.nix); this app only displays it, so the
# whole program is main.js plus the waiting page it shows until the service
# answers.
{
  electron,
  lib,
  makeWrapper,
  stdenv,
}:

stdenv.mkDerivation {
  pname = "dsh-desktop";
  version = "0.1.0";

  src = lib.cleanSource ./.;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ electron ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/dsh-desktop
    install -m644 main.js package.json starting.html $out/share/dsh-desktop/

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
