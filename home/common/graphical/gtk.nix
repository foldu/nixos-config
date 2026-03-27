{
  pkgs,
  config,
  getSettings,
  ...
}:
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

  gtk.gtk4.theme = config.gtk.theme;

  gtk.font = {
    name = configSettings.font.sans.name;
    size = configSettings.font.sans.size;
  };
}
