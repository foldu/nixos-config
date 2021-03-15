{ config, lib, pkgs, ... }:

{
  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.pop-icon-theme;
      name = "Pop";
    };
    theme = {
      package = pkgs.pop-gtk-theme;
      name = "Pop-dark";
    };
    gtk3.extraConfig.gtk-key-theme-name = "Emacs";
  };
}
