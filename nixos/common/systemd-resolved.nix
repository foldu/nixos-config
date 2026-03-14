{ ... }:
{
  services.resolved = {
    enable = true;
    settings.Resolve = {
      FallbackDNS = [
        "1.1.1.1"
        "1.0.0.1"
        "9.9.9.9"
      ];
      DNSSEC = false;
    };
  };
}
