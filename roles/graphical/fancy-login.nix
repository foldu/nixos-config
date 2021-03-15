{ pkgs, ... }:
{
  boot.plymouth = {
    enable = true;
  };

  services.xserver = {
    enable = true;
    displayManager = {
      sessionPackages = [ pkgs.sway ];
      gdm.enable = true;
      #lightdm.enable = true;
    };
  };
}
