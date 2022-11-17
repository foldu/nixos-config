{ config, lib, pkgs, ... }:
let
  iconTheme = "Adwaita";
  gtkTheme = "Adwaita";
in
{
  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.gnome.adwaita-icon-theme;
      name = iconTheme;
    };
    theme = {
      package = pkgs.adw-gtk3;
      name = "Adwaita-dark";
    };
    gtk3.extraConfig.gtk-key-theme-name = "Emacs";
  };

  xdg.configFile."gtk-4.0/settings.ini".text = ''
    [Settings]
    gtk-font-name=Inter 11
    gtk-icon-theme-name=${iconTheme}
    gtk-theme-name=${gtkTheme}
  '';
}
