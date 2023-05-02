{ ... }: {
  imports = [
    ../generic
    ../systemd-resolved.nix
  ];

  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";
  };
}
