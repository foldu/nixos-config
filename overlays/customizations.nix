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
}
