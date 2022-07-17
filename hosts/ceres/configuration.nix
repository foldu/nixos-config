{ config, lib, pkgs, ... }: {
  imports = [
    ./manual-hardware-configuration.nix
    ../../profiles/server.nix
    ../../profiles/home-dns.nix
    ../../profiles/home
  ];

  boot = {
    kernelPackages = lib.mkForce pkgs.linuxPackages_rpi4;
    kernelParams = [
      "usb-storage.quirks=152d:0578:u"
    ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  services.printing = {
    enable = true;
    drivers = [ pkgs.foo2zjs ];
  };

  networking.interfaces.eth0.useDHCP = true;

  services.borgbackup.repos = {
    backup-ssd = {
      allowSubRepos = true;
      authorizedKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEj/BMq4VOAyu8QPsJhpmwlz/VNImsKLrkS2ZYYAJRb8" ];
      path = "/var/backup";
    };
  };

  system.stateVersion = "21.03";
}
