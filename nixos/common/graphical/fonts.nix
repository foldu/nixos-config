{
  lib,
  pkgs,
  getSettings,
  ...
}:
let
  configSettings = getSettings pkgs;
in
{
  fonts = {
    fontDir.enable = true;
    fontconfig.defaultFonts = {
      sansSerif = [ configSettings.font.sans.name ];
      serif = [ configSettings.font.serif.name ];
      monospace = [ configSettings.font.monospace.name ];
    };
    fontconfig.hinting.enable = true;
    packages =
      with pkgs;
      [
        corefonts
        liberation_ttf
        noto-fonts
        dejavu_fonts
        #noto-fonts-cjk
        inter
        source-code-pro
        vistafonts
        etBook
        eb-garamond
        monaspace
        domitian
        jetbrains-mono
        ubuntu_font_family
        ibm-plex
        fira-mono
        nerd-fonts._0xproto
        maple-mono.NL-NF-CN-unhinted
      ]
      ++ lib.mapAttrsToList (_: f: f.pkg) configSettings.font;
  };
}
