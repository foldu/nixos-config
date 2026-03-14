{ pkgs, ... }:
{
  qt = {
    enable = true;
    style = "breeze";
    # platformTheme = "gnome";
  };
  environment.systemPackages = [
    pkgs.kdePackages.breeze-icons
    pkgs.kdePackages.breeze
  ];
}
