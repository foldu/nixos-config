{ pkgs, ... }:
{
  qt = {
    enable = true;
    style = "adwaita-dark";
  };
  #programs.qt5ct.enable = true;
  # environment.sessionVariables."QT_QPA_PLATFORM" = "xcb";
  #environment.systemPackages = [
  #  pkgs.breeze-gtk
  #  pkgs.breeze-icons
  #  pkgs.breeze-gtk
  #];
}
