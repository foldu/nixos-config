{ inputs, ... }:
{
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-gpu-amd

    ../common/profiles/server.nix

    ../common/zfs.nix
    ../common/cashewnix.nix
    ../common/gitlab-runner.nix

    ./hardware-configuration.nix
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
    ./lldap.nix
    ./wrrr.nix
    ./piped
    "${inputs.homeserver-sekret}"
  ];

  networking.hostName = "saturn";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostId = "964725e9";

  networking.networkmanager.enable = true;

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

  boot.enableContainers = false;
  users.users.barnabas.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIt82hTo4kjw6/T3bK+e5h3ZBMhV67/qIKEYaGTP/ETw saturn.home.5kw.li"
  ];

  system.stateVersion = "20.09";
}
