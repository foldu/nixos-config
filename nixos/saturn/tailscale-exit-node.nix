{ lib, ... }:
{
  boot.kernel.sysctl."net.ipv4.ip_forward" = lib.mkDefault true;
  services.tailscale.extraSetFlags = [ "--advertise-exit-node" ];
}
