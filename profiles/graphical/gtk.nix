{ config, lib, pkgs, ... }: 
let
  iconTheme = "Pop";
  gtkTheme = "Pop-dark";
in
{
  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.pop-icon-theme;
      name = iconTheme;
    };
    theme = {
      package = pkgs.pop-gtk-theme;
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
