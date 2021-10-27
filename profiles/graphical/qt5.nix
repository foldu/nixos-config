{ pkgs, ... }: {
  #programs.qt5ct.enable = true;
  #environment.sessionVariables."QT_QPA_PLATFORM" = "wayland";
  environment.systemPackages = [
    pkgs.breeze-gtk
    pkgs.breeze-icons
    pkgs.breeze-gtk
  ];
}
