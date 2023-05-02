{ inputs, ... }: {
  customizations = import ./customizations.nix;
  extra = import ./extra.nix;
  # extern = inputs.flake-utils.lib.eachDefaultSystem (system: {
  #   extraPackages = inputs.nixpkgs.lib.foldl (acc: x: acc // x.packages.${system}) { } [
  #     inputs.nix-stuff
  #     inputs.pickwp
  #     inputs.wpp-gtk
  #     inputs.random-scripts
  #   ];
  # });
}
