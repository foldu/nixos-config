{ pkgs, ... }:
{
  hardware.bluetooth = {
    enable = true;
    package = pkgs.bluez.overrideAttrs (old: {
      patches = [
        (pkgs.fetchpatch {
          url = "https://github.com/bluez/bluez/commit/066a164a524e4983b850f5659b921cb42f84a0e0.patch";
          sha256 = "sha256-I1WoBJZEZJ05hwGuksp52I4FLJ+jbG9t7U2sLTFmU0w=";
        })
      ];
    });
  };
}
