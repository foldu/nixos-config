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

    inputs.nixos-cosmic.nixosModules.default
    inputs.nixos-hardware.nixosModules.framework-13-7040-amd

    ../common/profiles/laptop.nix

    ../common/bluetooth.nix
    ../common/butter.nix
    ../common/cashewnix.nix
    ../common/graphical
  ];

  environment.sessionVariables = {
    MAKEFLAGS = "-j 12";
  };

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

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "venus"; # Define your hostname.

  services.desktopManager.cosmic.enable = true;

  system.stateVersion = "24.05"; # Did you read the comment?
}
