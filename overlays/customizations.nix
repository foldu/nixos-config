final: prev: {
  kitty = prev.kitty.overrideAttrs (oldAttrs: {
    postInstallPhase = ''
      sed -Ei 's/Exec=kitty/\0 --single-instance' $out/share/applications/kitty.desktop
    '';
  }
  );
  fish = prev.fish.overrideAttrs (oldAttrs:
    rec {
      pname = "fish";
      version = "3.4.0";
      src = prev.fetchurl {
        url = "https://github.com/fish-shell/fish-shell/releases/download/${version}/${pname}-${version}.tar.xz";
        sha256 = "sha256-tbSKuEhrGe9xajL39GuIuepTVhVfDpZ+6Z9Ak2RUE8U=";
      };
      patches = [ ];
    }
  );
  #gnome = prev.gnome // {
  #  mutter = prev.gnome.mutter.overrideAttrs (
  #    oldAttrs: rec {
  #      # wayland windows strobe on 41.3
  #      version = "41.2";
  #      src = prev.pkgs.fetchurl {
  #        url = "mirror://gnome/sources/mutter/${prev.lib.versions.major version}/${oldAttrs.pname}-${version}.tar.xz";
  #        sha256 = "AN+oEvHEhtdKK3P0IEWuEYL5JGx3lNZ9dLXlQ+pwBhc=";
  #      };
  #    }
  #  );
  #};
  brave = prev.brave.overrideAttrs (oldAttrs:
    {
      postFixup =
        let
          libPath = prev.lib.makeLibraryPath [ prev.libglvnd prev.wayland ];
          flags = [
            "--enable-features=UseOzonePlatform"
            "--ozone-platform=wayland"
            "--ignore-gpu-blocklist"
            "--enable-gpu-rasterization"
            "--enable-zero-copy"
          ];
          flagString = prev.lib.concatStringsSep " " flags;
        in
        # FIXME: this is a terrible abomination
        ''
          sed -i -E 's/^exec.+/\0 ${flagString}/' "$out/bin/brave"
          sed -i -E 's|^exec.+|export LD_LIBRARY_PATH=${libPath}\n\0|' "$out/bin/brave"
        '';
    });
}
