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
      inter
      vistafonts
      jetbrains-mono
      ubuntu_font_family
      ibm-plex
      fira-mono
      (nerdfonts.override {
        fonts = [
          "3270"
        ];
      })
    ] ++ lib.mapAttrsToList (_: f: f.pkg) configSettings.font;
  };

  home-manager.users.barnabas = { config, ... }: {
    gtk.font = {
      name = configSettings.font.sans.name;
      size = configSettings.font.sans.size;
    };
  };
}
