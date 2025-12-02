{ pkgs, ... }:
{
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    konsole
    elisa
  ];
  services.desktopManager.plasma6.enable = true;
}
