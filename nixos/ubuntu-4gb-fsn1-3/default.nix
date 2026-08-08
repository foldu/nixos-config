{ pkgs, lib, ... }:
{
  imports = [
    ../common/profiles/server.nix

    ./hardware-configuration.nix

    ./mirko.nix
    #./opencloud.nix
    ./tandoor.nix
    ./netbird.nix
  ];

  # Hetzner ARM VM (virtio/xen): no special firmware needed
  # saves ~700MB closure size
  # cfg80211 will log a harmless "failed to load regulatory.db" at boot, nobody cares.
  hardware.enableRedistributableFirmware = lib.mkForce false;
  hardware.firmware = lib.mkForce [ ];

  boot.enableContainers = false;

  virtualisation.podman = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  sops.defaultSopsFile = ../../secrets/hetzner.yaml;

  virtualisation.oci-containers.backend = "podman";

  networking.hostName = "ubuntu-4gb-fsn1-3";

  # backup dns
  networking.resolvconf.extraConfig = ''
    name_servers_append='1.1.1.1'
  '';
  networking.useDHCP = true;
  networking.defaultGateway6 = {
    address = "fe80::1";
    interface = "eth0";
  };
  networking.interfaces.eth0.ipv6.addresses = [
    {
      address = "2a01:4f8:c17:d395::1";
      prefixLength = 64;
    }
  ];

  users.users.root = {
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIz6r//vC1t/e+04wxXfSbwAOhDvFGLs/fk+nJ8+8h+J"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICYIoS0rws4d2SRNxiu02i8XA45K3E5dh6liyHL60AnC"
    ];
  };

  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];
    allowedUDPPortRanges = [
      {
        from = 51821;
        to = 51825;
      }
    ];
  };

  environment.systemPackages = with pkgs; [
    htop
    fastfetch
    tmux
    git
  ];

  services.openssh = {
    settings = {
      AuthenticationMethods = "publickey";
    };
    ports = [ 34950 ];
  };

  services.caddy = {
    enable = true;
    email = "foldu@protonmail.com";
    acmeCA = "https://acme-v02.api.letsencrypt.org/directory";
  };

  system.stateVersion = "21.03";
}
