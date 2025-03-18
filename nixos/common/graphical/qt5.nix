{ pkgs, ... }:
{
  qt = {
    enable = true;
    style = "kvantum";
    platformTheme = "qt5ct";
  };
  #programs.qt5ct.enable = true;
  # environment.sessionVariables."QT_QPA_PLATFORM" = "xcb";
  environment.systemPackages = [
    pkgs.kdePackages.breeze-icons
    pkgs.kdePackages.breeze
  ];
}
