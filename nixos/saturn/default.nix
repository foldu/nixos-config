{ pkgs, inputs, ... }: {
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-gpu-amd

    ../common/profiles/server.nix

    ../common/dns-server.nix
    ../common/zfs.nix

    ./hardware-configuration.nix
    ./backups.nix
    ./file-server.nix
    ./gitea.nix
    ./hydra.nix
    ./jellyfin.nix
    ./libreddit.nix
    ./nitter.nix
    ./step-ca.nix
    ./transmission.nix
    ./vaultwarden.nix
    ./piped
    ./unifi.nix
    ./miniflux.nix
    ./postgresql.nix
    ./metrics
    "${inputs.homeserver-sekret}"

  ];

  networking.hostName = "saturn";

  boot.loader.grub = {
    enable = true;
    device = "/dev/disk/by-id/ata-Crucial_CT250MX200SSD1_153610838381";
  };

  networking.hostId = "964725e9";

  networking.interfaces.enp5s0.useDHCP = true;

  virtualisation.podman = {
    enable = true;
    extraPackages = [ pkgs.zfs pkgs.netavark ];
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  services.caddy = {
    enable = true;
    acmeCA = "https://ca.home.5kw.li:4321/acme/acme/directory";
    email = "webmaster@5kw.li";
  };

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [
    80
    443
  ];

  networking.firewall.interfaces."tailscale0".allowedUDPPorts = [
    80
    443
  ];

  virtualisation.oci-containers.backend = "podman";

  boot.enableContainers = false;

  # FIXME: doesn't work
  systemd.timers.podman-auto-update = {
    timerConfig.OnCalendar = "03:00";
    wantedBy = [ "timers.target" ];
  };
  system.stateVersion = "20.09";
}
