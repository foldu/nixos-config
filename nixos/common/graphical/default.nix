{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./corectrl.nix
    ./desktop-portal.nix
    ./fancy-login.nix
    ./fonts.nix
    ./gnome.nix
    ./nfs.nix
    ./pipewire.nix
    ./qt5.nix
    ./syncthing.nix
    ./game-devices.nix
    inputs.nixos-cosmic.nixosModules.default
  ];

  services.desktopManager.cosmic.enable = true;

  programs.kdeconnect.enable = true;

  # services.printing = {
  #   enable = true;
  #
  #   clientConf = ''
  #     ServerName ceres.home.5kw.li
  #     Encryption Never
  #   '';
  # };

  documentation = {
    dev.enable = true;
    info.enable = false;
  };

  services.flatpak.enable = true;

  networking.firewall.enable = true;

  programs.dconf.enable = true;

  hardware.graphics.enable = true;

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

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
