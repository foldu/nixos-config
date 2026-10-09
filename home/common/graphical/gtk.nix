{
  pkgs,
  config,
  getSettings,
  ...
}:
let
  iconTheme = "Adwaita";
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
    gtk3.extraConfig = {
      gtk-key-theme-name = "Emacs";
      # Chromium — and so Electron's window frame, which Chromium draws itself
      # under Wayland — takes its light/dark decision from this GTK3 setting,
      # not from the theme name above. Without it the frame renders as light
      # Adwaita however dark the configured theme is.
      gtk-application-prefer-dark-theme = true;
    };
  };

  gtk.gtk4.theme = config.gtk.theme;

  gtk.font = {
    name = configSettings.font.sans.name;
    size = configSettings.font.sans.size;
  };
}
