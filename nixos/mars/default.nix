{ inputs, ... }:
{
  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t14-amd-gen1

    ../common/profiles/laptop.nix

    ../common/bluetooth.nix
    ../common/graphical
    ../common/butter.nix

    ./manual-hardware-configuration.nix
  ];

  networking.hostName = "mars";

  # uefi suxxxxx
  boot.loader = {
    efi = {
      #canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
    grub = {
      enable = true;
      device = "nodev";
      efiInstallAsRemovable = true;
      efiSupport = true;
    };
  };

  environment.sessionVariables = {
    MAKEFLAGS = "-j 16";
  };

  zramSwap.enable = true;

  system.stateVersion = "20.09";
}
