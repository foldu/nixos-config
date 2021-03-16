{ config, lib, pkgs, ... }: {
  imports = [
    ./generic.nix
    ../terminal-environment.nix
  ];

  networking.firewall.enable = true;
}
