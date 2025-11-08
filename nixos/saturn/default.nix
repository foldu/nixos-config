{ inputs, pkgs, ... }:
{
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-gpu-amd

    ../common/profiles/server.nix

    ../common/zfs.nix
    ../common/cashewnix.nix
    ../common/gitlab-runner.nix
    ../common/nivea.nix

    ./hardware-configuration.nix
    ./imgen.nix
    ./backups.nix
    ./file-server.nix
    ./gitlab
    ./jellyfin.nix
    ./redlib
    ./step-ca.nix
    ./transmission
    ./vaultwarden.nix
    ./miniflux.nix
    ./postgresql.nix
    ./metrics
    ./podman
    ./invidious.nix
    ./ffsync.nix
    ./navidrome.nix
    ./open-webui.nix
    ./tailscale-exit-node.nix
    ./auth
    ./wrrr.nix
    ./piped
    ./llama-swap.nix
    "${inputs.homeserver-sekret}"
  ];

  # enable serial console
  boot.kernelParams = [ "console=ttyS0" ];

  networking.hostName = "saturn";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostId = "964725e9";

  networking.networkmanager.enable = true;

  services.caddy = {
    enable = true;
    email = "foldu@protonmail.com";
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/ovh@v1.1.0" ];
      hash = "sha256-EOlZ594X3IE1j2uORW8n9gtRfQR/IBIPYyriH2bUpts=";
    };
    globalConfig = ''
      acme_dns ovh {
        endpoint ovh-eu
        application_key {$OVH_APPLICATION_KEY}
        application_secret {$OVH_APPLICATION_SECRET}
        consumer_key {$OVH_CONSUMER_KEY}
      }
    '';
    environmentFile = "/var/secrets/caddy.env";
    logFormat = "level INFO";
  };

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [
    80
    443
  ];

  networking.firewall.interfaces."tailscale0".allowedUDPPorts = [
    80
    443
  ];

  boot.enableContainers = false;
  users.users.barnabas.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIt82hTo4kjw6/T3bK+e5h3ZBMhV67/qIKEYaGTP/ETw saturn.home.5kw.li"
  ];

  services.qemuGuest.enable = true;

  system.stateVersion = "20.09";
}
