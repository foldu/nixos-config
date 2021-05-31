{ config, lib, pkgs, ... }:
let
  iconTheme = "Yaru";
  gtkTheme = "Yaru-dark";
in
{
  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.yaru-theme;
      name = iconTheme;
    };
    theme = {
      package = pkgs.yaru-theme;
      name = gtkTheme;
    };
    gtk3.extraConfig.gtk-key-theme-name = "Emacs";
  };

  xdg.configFile."gtk-4.0/settings.ini".text = ''
    [Settings]
    gtk-application-prefer-dark-theme=1
    gtk-font-name=Inter 11
    gtk-icon-theme-name=${iconTheme}
    gtk-theme-name=${gtkTheme}
  '';
}
