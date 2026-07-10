{ config, ... }:
{
  imports = [ ./cashewnix.nix ];

  sops.secrets."cashewnix-private" = { };

  services.cashewnix = {
    privateKeyPath = config.sops.secrets."cashewnix-private".path;
    enableNixServe = true;
  };

  services.nix-serve.openFirewall = true;
}
