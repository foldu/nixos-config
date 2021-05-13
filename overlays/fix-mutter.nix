final: prev: {
  gnome = prev.gnome.overrideScope' (gnomeFinal: gnomePrev: {
    mutter = gnomePrev.mutter.overrideAttrs (oldAttrs: {
      patches = (oldAttrs.patches or [ ]) ++ [
        # fixes https://github.com/pop-os/shell/issues/912
        (prev.fetchpatch {
          url = "https://gitlab.gnome.org/GNOME/mutter/-/commit/90e3d9782d8245f6cdb64111acf156a92037d938.patch";
          sha256 = "sha256-UgKBzjr7ncxplNh2d5t7at7+GmMZf04YPZr7ru6O5nc=";
        })
      ];
    });
  });
}
