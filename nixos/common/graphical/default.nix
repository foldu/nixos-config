{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./corectrl.nix
    ./fancy-login.nix
    ./fonts.nix
    ./pipewire.nix
    ./qt.nix
    ./syncthing.nix
    ./gaming.nix
    ./samba.nix
    ./vm.nix
    ./niri.nix
    ./sddm.nix
    ./plasma.nix
  ];

  # enable wayland for electron apps
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  programs.kdeconnect = {
    enable = true;
  };

  documentation = {
    dev.enable = true;
    info.enable = false;
  };

  services.flatpak.enable = true;

  networking.firewall.enable = true;

  programs.dconf.enable = true;

  hardware.graphics.enable = true;

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  # https://gitlab.freedesktop.org/drm/amd/-/issues/3693#note_2715660
  # boot.extraModulePackages = [
  #   pkgs.amdgpu-module
  # ];

  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };

  services.udev.extraRules = ''
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3748", \
    MODE:="0666", \
    SYMLINK+="stlinkv2_%n"
  '';
}
