{ config, ... }:
let
  harmoniaPort = 5000;
in
{
  imports = [ ./cashewnix.nix ];

  sops.secrets."cashewnix-private" = { };

  services.cashewnix = {
    privateKeyPath = config.sops.secrets."cashewnix-private".path;
    settings.local_binary_caches.local_cache = {
      advertise = "ip";
      port = harmoniaPort;
    };
  };

  services.harmonia.cache = {
    enable = true;
    signKeyPaths = [ config.sops.secrets."cashewnix-private".path ];
    settings = {
      bind = "0.0.0.0:${toString harmoniaPort}";
    };
  };

  networking.firewall.allowedTCPPorts = [ harmoniaPort ];
}
