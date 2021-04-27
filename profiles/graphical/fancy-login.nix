{ pkgs, ... }:
{
  boot.plymouth = {
    enable = true;
  };

  services.xserver = {
    enable = true;
    displayManager = {
      gdm = {
        enable = true;
        autoSuspend = false;
      };
    };
  };
}
