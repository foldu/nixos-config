{ ... }:
let
  harmoniaPort = 5000;
in
{
  services.nix-cache-beacon = {
    # Announce cache to the local network
    advert = {
      enable = true;
      port = harmoniaPort;
    };
  };

  # Local binary cache using Harmonia
  # nix-cache-beacon can be used with any cache implementation
  services.harmonia.cache = {
    enable = true;
    signKeyPaths = [ "/var/secrets/nix-cache-beacon-key" ];
  };

  networking.firewall.allowedTCPPorts = [
    harmoniaPort
  ];
}
