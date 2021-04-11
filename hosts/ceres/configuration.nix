{ config, lib, pkgs, ... }: {
  imports = [
    ../../profiles/server.nix
    ../../profiles/home-dns.nix
    ../../profiles/home.nix
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

  services.printing = {
    enable = true;
    drivers = [ pkgs.foo2zjs ];
  };

  networking.interfaces.eth0.useDHCP = true;

  services.journald.extraConfig = ''
    Storage=volatile
  '';

  services.borgbackup.repos = {
    backup-ssd = {
      allowSubRepos = true;
      authorizedKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEj/BMq4VOAyu8QPsJhpmwlz/VNImsKLrkS2ZYYAJRb8" ];
      path = "/var/backup";
    };
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/886e8c0f-209e-48c0-a749-2e090802aca5";
    options = [
      "compression=zstd"
      "noatime"
    ];
    fsType = "btrfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/BBAE-10F7";
    fsType = "vfat";
  };

  system.stateVersion = "21.03";

  home-manager.sharedModules = [{ manual.manpages.enable = false; }];

  swapDevices = [ ];
  nix.maxJobs = lib.mkDefault 4;
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
  boot.initrd.availableKernelModules = [
    "usbhid"
    "btrfs"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
}
