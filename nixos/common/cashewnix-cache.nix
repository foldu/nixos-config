{ config, lib, ... }:
{
  imports = [ ./cashewnix.nix ];

  services.cashewnix = {
    settings = {
      local_binary_caches = {
        local_cache = {
          advertise = "Ip";
          port = config.services.nix-serve.port;
        };
      };
    };
    privateKeyPath = "/var/secrets/cashewnix-private";
    openNixServeFirewall = true;
    enableNixServe = true;
  };
}
