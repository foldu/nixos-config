{ ... }:
{
  imports = [
    ../common/generic.nix
    ../common/dev
    ../common/terminal
    ../common/graphical
    ../common/gnome
  ];

  services.easyeffects = {
    enable = true;
    extraPresets = {
      framework13 = builtins.fromJSON (builtins.readFile ./fw13-easy-effects.json);
    };
  };
}
