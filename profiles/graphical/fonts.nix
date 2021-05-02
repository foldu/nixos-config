{ config, lib, pkgs, configSettings, ... }:

{
  fonts = {
    fontDir.enable = true;
    fontconfig.defaultFonts = {
      sansSerif = [ configSettings.font.sans.name ];
      serif = [ configSettings.font.serif.name ];
      monospace = [ configSettings.font.monospace.name ];
    };
    fontconfig.hinting.enable = true;
    fonts = with pkgs; [
      corefonts
      noto-fonts
      dejavu_fonts
      noto-fonts-cjk
      ibm-plex
      source-code-pro
      fira-mono
      libertine
      inconsolata
      cascadia-code
      inter
      vistafonts
      iosevka
      etBook
      jetbrains-mono
    ] ++ lib.mapAttrsToList (_: f: f.pkg) configSettings.font;
  };

  home-manager.users.barnabas = { config, ... }: {
    gtk.font = {
      name = configSettings.font.sans.name;
      size = configSettings.font.sans.size;
    };
  };
}
