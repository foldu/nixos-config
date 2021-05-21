final: prev: {
  kitty = prev.kitty.overrideAttrs (
    oldAttrs: {
      postInstallPhase = ''
        sed -Ei 's/Exec=kitty/\0 --single-instance' $out/share/applications/kitty.desktop
      '';
    }
  );
}
