{ config, lib, pkgs, ... }:
let
  ssdRoot = "/run/media/ext-ssd";
in
{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/server.nix
    ../../profiles/home-dns.nix
  ];

  boot = {
    kernelPackages = lib.mkForce pkgs.linuxPackages_rpi4;
    loader = {
      grub.enable = false;
      raspberryPi = {
        enable = true;
        version = 4;
      };
    };
  };

  boot.loader.generic-extlinux-compatible.enable = true;

  services.printing = {
    enable = true;
    drivers = [ pkgs.foo2zjs ];
  };

  networking.interfaces.eht0.useDHCP = true;

  services.journald.extraConfig = ''
    Storage=volatile
  '';

  services.borgbackup.repos = {
    backup-ssd = {
      allowSubRepos = true;
      authorizedKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEj/BMq4VOAyu8QPsJhpmwlz/VNImsKLrkS2ZYYAJRb8" ];
      path = "${ssdRoot}/backup";
    };
  };

  fileSystems."${ssdRoot}" = {
    device = "/dev/disk/by-uuid/2d9dc857-8fd9-49da-b974-40f7ab803713";
    fsType = "xfs";
  };

  system.stateVersion = "20.09";
}
