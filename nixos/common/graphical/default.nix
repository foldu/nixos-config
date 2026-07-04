{
  pkgs,
  inputs,
  lib,
  ...
}:
{
  imports = [
    ./fancy-login.nix
    ./fonts.nix
    ./pipewire.nix
    ./qt.nix
    ./syncthing.nix
    ./gaming.nix
    ./samba.nix
    ./niri.nix
    ./gnome.nix
  ];

  nixpkgs.overlays = [
    inputs.nix-cachyos-kernel.overlays.pinned
  ];

  services.displayManager.defaultSession = "niri";
  services.displayManager.gdm = {
    enable = true;
    autoSuspend = false;
  };

  # enable wayland for electron apps
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = [ pkgs.bitwarden-desktop ];
  # FIXME:
  # bitwarden uses EOL electron
  nixpkgs.config.permittedInsecurePackages = [
    "electron-39.8.10"
  ];

  documentation = {
    dev.enable = true;
    info.enable = false;
  };

  # needs downgrade due to https://github.com/flatpak/flatpak/issues/6717
  services.flatpak = {
    enable = true;
    package = pkgs.flatpak.overrideAttrs (oldAttrs: rec {
      version = "1.16.6";
      src = pkgs.fetchurl {
        url = "https://github.com/flatpak/flatpak/releases/download/${version}/flatpak-${version}.tar.xz";
        hash = "sha256-HmPn8/5EtgLzTZKm/kb9ijvGvpRgwDwmgeV5dsZY7sM=";
      };
    });
  };

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

  programs.nix-ld.enable = true;
}
