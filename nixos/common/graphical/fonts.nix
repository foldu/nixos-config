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
    # The CJK faces come after our Latin ones so CJK text keeps our UI font for
    # what it covers. Noto's collection ships one face per language variant and
    # fontconfig has no reason to prefer SC over JP/KR/TC, so without naming the
    # SC face here Chinese text renders with Japanese or Korean glyph variants.
    fontconfig.defaultFonts = {
      sansSerif = [
        configSettings.font.sans.name
        "Noto Sans CJK SC"
      ];
      serif = [
        configSettings.font.serif.name
        "Noto Serif CJK SC"
      ];
      monospace = [
        configSettings.font.monospace.name
        "Noto Sans Mono CJK SC"
      ];
    };
    fontconfig = {
      hinting = {
        enable = true;
        style = "full";
        autohint = false;
      };
      antialias = true;
      subpixel = {
        lcdfilter = "default";
        rgba = "rgb";
      };
    };
    packages =
      with pkgs;
      [
        material-symbols
        corefonts
        liberation_ttf
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
        dejavu_fonts
        inter
        source-code-pro
        vista-fonts
        et-book
        eb-garamond
        monaspace
        domitian
        # jetbrains-mono
        ubuntu-classic
        ibm-plex
        fira-mono
        nerd-fonts._0xproto
        maple-mono.NL-NF-CN-unhinted
      ]
      ++ lib.mapAttrsToList (_: f: f.pkg) configSettings.font;
  };
}
