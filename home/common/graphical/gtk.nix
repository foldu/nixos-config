{ pkgs, getSettings, ... }:
let
  iconTheme = "Adwaita";
  gtkTheme = "Adwaita";
  configSettings = getSettings pkgs;
in
{
  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.adwaita-icon-theme;
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

  gtk.font = {
    name = configSettings.font.sans.name;
    size = configSettings.font.sans.size;
  };
}
