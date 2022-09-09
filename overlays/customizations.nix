final: prev: {
  kitty = prev.kitty.overrideAttrs (oldAttrs: {
    postInstallPhase = ''
      sed -Ei 's/Exec=kitty/\0 --single-instance' $out/share/applications/kitty.desktop
    '';
  }
  );
  gnome = prev.gnome // {
    #mutter = prev.gnome.mutter.overrideAttrs (
    #  oldAttrs: rec {
    #    patches = [
    #      # dynamic triple/double buffering https://gitlab.gnome.org/GNOME/mutter/-/merge_requests/1441
    #      (prev.fetchpatch {
    #        url = "https://gitlab.gnome.org/GNOME/mutter/-/merge_requests/2487.patch";
    #        sha256 = "sha256-WvzhpUoCvhYncnPEeTpWnoeQWptmXQS6sA5fVcuOfDY=";
    #      })
    #    ];
    #  }
    #);
  };
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
