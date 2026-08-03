{ pkgs, inputs, ... }:
{
  imports = [
    ./telegraf.nix
  ];

  environment.systemPackages = [
    inputs.home-manager.packages.${pkgs.stdenv.hostPlatform.system}.home-manager
  ];
}
