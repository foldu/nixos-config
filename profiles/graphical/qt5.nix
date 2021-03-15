{ pkgs, ... }:
{
  programs.qt5ct.enable = true;
  environment.systemPackages = [
    pkgs.breeze-gtk
    pkgs.breeze-icons
    pkgs.breeze-gtk
  ];
}
