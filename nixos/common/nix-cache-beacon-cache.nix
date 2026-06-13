{ ... }:
{
  services.nix-cache-beacon = {
    # Announce cache to the local network
    advert = {
      enable = true;
      port = 5000; # Harmonia port
    };
  };

  # Local binary cache using Harmonia
  # nix-cache-beacon can be used with any cache implementation
  services.harmonia.cache.enable = true; # Serve up local Nix store
  services.harmonia.signKeyPaths = [ "/var/secrets/nix-cache-beacon-key" ];
}
