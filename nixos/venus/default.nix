{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    inputs.nixos-hardware.nixosModules.framework-13-7040-amd

    ../common/profiles/laptop.nix

    ../common/bluetooth.nix
    ../common/butter.nix
    ../common/cashewnix.nix
    ../common/graphical

    inputs.quadlet-nix.nixosModules.quadlet
  ];

  environment.sessionVariables = {
    MAKEFLAGS = "-j 12";
  };

  programs.nix-ld.enable = true;

  # https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate#Hibernation_into_swap_file
  boot.resumeDevice = "/dev/nvme0n1p2";
  # found out via btrfs inspect-internal map-swapfile -r /swap/swapfile
  boot.kernelParams = [ "resume_offset=533760" ];

  # go into hibernate after being suspended for 30minutes
  # https://wiki.nixos.org/wiki/Power_Management#Go_into_hibernate_after_specific_suspend_time
  systemd.sleep.settings.Sleep.HibernateDelaySec = "30m";

  networking.nftables = {
    enable = true;
    tables.excludeTraffic = {
      name = "excludeTraffic";
      family = "inet";
      content = ''
        chain excludeOutgoing {
          type route hook output priority 0; policy accept;
          ip daddr 100.64.0.0/10 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;
        }
        chain excludeDns {
          type filter hook output priority -10; policy accept;
          ip daddr 100.64.0.3 udp dport 53 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;
          ip daddr 100.64.0.3 tcp dport 53 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;
        }
      '';
    };
  };

  services.fwupd.enable = true;

  hardware.amdgpu.opencl.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.limine.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "venus"; # Define your hostname.

  services.colord.enable = true;

  users.users.barnabas.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC7S1RuayMtU1b9g6rLIcYFvdhTFphIZiK2RdeV4fYNP venus.home.5kw.li"
  ];

  system.stateVersion = "24.05"; # Did you read the comment?
}
