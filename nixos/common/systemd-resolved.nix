{ pkgs, ... }:
{
  services.resolved = {
    enable = true;
    dnssec = "false";
    fallbackDns = [
      "1.1.1.1"
      "1.0.0.1"
      "9.9.9.9"
    ];
  };
}
