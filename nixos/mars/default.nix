{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t14-amd-gen1

    ../common/profiles/laptop.nix

    ../common/bluetooth.nix
    ../common/graphical
    ../common/butter.nix
    ../common/cashewnix-cache.nix

    ./manual-hardware-configuration.nix
  ];
  services.printing = {
    enable = true;
    drivers = [ pkgs.foo2zjs ];
    defaultShared = true;
    allowFrom = [
      "localhost"
      "print.home.5kw.li"
    ];
    listenAddresses = [
      "localhost:631"
      "print.home.5kw.li:631"
    ];
    startWhenNeeded = false;
  };

  networking.firewall.allowedTCPPorts = [ 631 ];

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

  system.stateVersion = "20.09";
}
