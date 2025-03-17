{ pkgs, inputs, ... }:
{
  imports = [ inputs.niri-flake.nixosModules.niri ];

  services.dbus.packages = with pkgs; [
    gcr
    gnome-settings-daemon
  ];

  services.gvfs.enable = true;
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # programs.niri = {
  #   enable = true;
  # };
}
