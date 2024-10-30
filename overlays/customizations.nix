final: prev: {
  gnome-keyring = prev.gnome-keyring.overrideAttrs (oldAttrs: {
    postInstall = ''
      sed -E 's/OnlyShowIn.+/\0COSMIC;/g' -i $out/etc/xdg/autostart/*.desktop
    '';
  });
  brave = prev.brave.overrideAttrs (oldAttrs: {
    postFixup =
      let
        libPath = prev.lib.makeLibraryPath [
          prev.libglvnd
          prev.wayland
        ];
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
