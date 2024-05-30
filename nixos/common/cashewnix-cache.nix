{ config, lib, ... }:
{
  imports = [ ./cashewnix.nix ];

  services.cashewnix = {
    privateKeyPath = "/var/secrets/cashewnix-private";
    enableNixServe = true;
  };

  services.nix-serve.openFirewall = true;
}
