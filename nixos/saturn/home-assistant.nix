{ ... }:
{
  networking.nftables = {
    enable = true;
  };
  virtualisation.incus = {
    enable = true;
    preseed = {
      networks = [
        {
          config = {
            "ipv4.address" = "10.0.32.1/24";
            "ipv4.nat" = "true";
          };
          name = "incusbr0";
          type = "bridge";
        }
      ];
      profiles = [
        {
          devices = {
            eth420 = {
              name = "eth420";
              network = "incusbr0";
              type = "nic";
            };
            root = {
              path = "/";
              pool = "default";
              size = "35GiB";
              type = "disk";
            };
          };
          name = "default";
        }
      ];
      storage_pools = [
        {
          config = {
            source = "rpool/system/incus";
          };
          driver = "zfs";
          name = "default";
        }
      ];
    };
  };
  networking.firewall.interfaces.incusbr0.allowedTCPPorts = [
    53
    67
  ];
  networking.firewall.interfaces.incusbr0.allowedUDPPorts = [
    53
    67
  ];
}
