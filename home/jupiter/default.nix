{ ... }:
{
  imports = [
    ../common/generic.nix
    ../common/dev
    ../common/terminal
    ../common/graphical
    ../common/gnome

    ./beets.nix
  ];

  home.stateVersion =  "24.05";
}
