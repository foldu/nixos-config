final: prev: {
  # pnpm 12.7+ no longer fetches optional dependencies for other platforms,
  # even with --force, so authelia's pnpmDeps hash mismatches. Setting
  # forceIgnoresPlatform restores the old, platform-independent output.
  # Remove once fetchPnpmDeps does this itself:
  # https://github.com/NixOS/nixpkgs/issues/571789
  authelia = prev.authelia.override {
    authelia-web = prev.authelia.web.override {
      fetchPnpmDeps =
        args:
        prev.fetchPnpmDeps (
          args
          // {
            prePnpmInstall = "export pnpm_config_force_ignores_platform=true";
          }
        );
    };
  };

  # gnome-keyring = prev.gnome-keyring.overrideAttrs (oldAttrs: {
  #   postInstall = ''
  #     sed -E 's/OnlyShowIn.+/\0COSMIC;/g' -i $out/etc/xdg/autostart/*.desktop
  #   '';
  # });
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
