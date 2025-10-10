{ pkgs, ... }:
{
  qt = {
    enable = true;
    style = "adwaita-dark";
    platformTheme = "gnome";
  };
  environment.systemPackages = [
    pkgs.kdePackages.breeze-icons
    pkgs.kdePackages.breeze
  ];
}
