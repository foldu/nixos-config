{ config, inputs, pkgs, ... }:
{
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-gpu-amd

    ../common/profiles/server.nix
    ../common/home

    ../common/zfs.nix
    ../common/gitlab-runner.nix
    ../common/nivea.nix
    ../common/systemd-resolved.nix
    ../common/cashewnix.nix

    ./hardware-configuration.nix
    ./imgen.nix
    ./bambu.nix
    ./postgresql-backup.nix
    ./file-server.nix
    ./gitlab
    ./jellyfin.nix
    ./redlib.nix
    ./transmission
    ./vaultwarden.nix
    ./postgresql.nix
    ./metrics
    ./podman
    ./invidious.nix
    ./navidrome.nix
    ./auth
    ./wrrr.nix
    ./paperless.nix
    # ./piped
    ./llama.nix
    ./materialious.nix
    ./img-bookmark.nix
    ./grafana
    "${inputs.homeserver-sekret}"
  ];

  # enable serial console
  boot.kernelParams = [ "console=ttyS0" ];

  networking.hostName = "saturn";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostId = "964725e9";

  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";
  };

  sops.secrets."caddy/env" = { };

  services.caddy = {
    enable = true;
    email = "foldu@protonmail.com";
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/ovh@v1.1.0" ];
      # don't forget to update this caddy hash/caddyhash
      hash = "sha256-/xpTqYydmJEthBgGJ3uZ9FDF19dlvWs0h8XUf8KkS/M=";
    };
    globalConfig = ''
      acme_dns ovh {
        endpoint ovh-eu
        application_key {$OVH_APPLICATION_KEY}
        application_secret {$OVH_APPLICATION_SECRET}
        consumer_key {$OVH_CONSUMER_KEY}
      }
    '';
    environmentFile = config.sops.secrets."caddy/env".path;
    virtualHosts."hass.home.5kw.li" = {
      extraConfig = ''
        encode zstd gzip
        reverse_proxy 172.25.74.192:8123
      '';
    };
  };

  # The container bridges need 80/443 too, otherwise gitlab-runner
  # containers (bridge networking) can't reach caddy and require the old
  # host-networking hack.
  networking.firewall.interfaces."wt0".allowedTCPPorts = [
    80
    443
  ];

  networking.firewall.interfaces."wt0".allowedUDPPorts = [
    80
    443
  ];

  # victoriametrics on the LAN so everyone can push metrics
  # directly to the influxdb endpoint
  networking.firewall.interfaces.ens18.allowedTCPPorts = [
    8428
  ];

  networking.firewall.interfaces.docker0.allowedTCPPorts = [
    80
    443
  ];

  networking.firewall.interfaces.podman0.allowedTCPPorts = [
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
