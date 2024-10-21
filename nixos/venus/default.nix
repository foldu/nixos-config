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

  services.fwupd.enable = true;

  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_10;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "venus"; # Define your hostname.

  services.desktopManager.cosmic.enable = true;

  system.stateVersion = "24.05"; # Did you read the comment?
}
