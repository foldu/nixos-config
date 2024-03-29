{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  lol = pkgs.stdenv.mkDerivation {
    pname = "ble-ws-central-dbus";
    src = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE busconfig PUBLIC
      "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
      "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
      <busconfig>
        <policy user="barnabas">
          <allow own="li._5kw.BleWsCentral"/>
        </policy>
        <policy context="default">
          <allow send_destination="li._5kw.BleWsCentral"/>
          <allow receive_sender="li._5kw.BleWsCentral"/>
        </policy>
      </busconfig>
    '';
    dontUnpack = true;
    version = "0.1";
    installPhase = ''
      mkdir -p "$out/share/dbus-1/system.d"
      echo "$src" > "$out/share/dbus-1/system.d/li._5kw.BleWsCentral.conf"
    '';
  };
in
{
  imports = [
    ./bfq.nix
    ./desktop-portal.nix
    ./fancy-login.nix
    ./fonts.nix
    ./gnome.nix
    ./nfs.nix
    ./pipewire.nix
    ./qt5.nix
    ./syncthing.nix
    ./podman.nix
    ./game-devices.nix
  ];

  programs.kdeconnect.enable = true;

  services.printing = {
    enable = true;

    clientConf = ''
      ServerName ceres.home.5kw.li
      Encryption Never
    '';
  };

  documentation = {
    dev.enable = true;
    info.enable = false;
  };

  environment.systemPackages = [ lol ];

  services.flatpak.enable = true;

  networking.firewall.enable = true;

  programs.dconf.enable = true;

  hardware.opengl.enable = true;

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  services.udev.extraRules = ''
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3748", \
    MODE:="0666", \
    SYMLINK+="stlinkv2_%n"
  '';
}
