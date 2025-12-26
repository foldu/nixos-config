{ pkgs, ... }:
{
  # see https://wiki.cachyos.org/configuration/gaming/ for tuning options

  # enable ntsync kernel module, which could/should speed up proton
  boot.kernelModules = [ "ntsync" ];

  environment.sessionVariables = {
    # breaks steam overlay but removes x11
    PROTON_ENABLE_WAYLAND = "1";
    # enables hdr, with PROTON_ENABLE_WAYLAND being necessary
    PROTON_ENABLE_HDR = "1";
    # actually use ntsync instead of the wine implementation
    PROTON_USE_NTSYNC = "1";
    # disables wm decorations, may fix window clicky not doing the clicky
    PROTON_NO_WM_DECORATION = "1";
    # enables mangohud globally
    MANGOHUD = "1";
  };

  services.udev.packages = [ pkgs.game-devices-udev-rules ];

  hardware.uinput.enable = true;
}
