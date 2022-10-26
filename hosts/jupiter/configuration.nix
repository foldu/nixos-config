{ config, lib, pkgs, ... }: {
  imports = [
    ../../profiles/amd-gpu.nix
    ../../profiles/bluetooth.nix
    ../../profiles/desktop.nix
    ../../profiles/graphical
    ../../profiles/home
    ../../profiles/x86.nix
    ./hardware-configuration.nix
    ../../profiles/builder.nix
  ];

  boot.loader = {
    systemd-boot = {
      enable = true;
      editor = false;
    };
    efi.canTouchEfiVariables = true;
  };

  environment.sessionVariables = {
    MAKEFLAGS = "-j 32";
  };

  fileSystems."/var/lib/docker" = {
    device = "/home/docker";
    fsType = "none";
    options = [ "defaults" "bind" ];
  };

  services.nix-serve = {
    enable = true;
    secretKeyFile = "/var/secrets/cache-priv-key.pem";
  };

  services.caddy = {
    enable = true;
    acmeCA = "https://ca.home.5kw.li:4321/acme/acme/directory";
    email = "webmaster@5kw.li";
    extraConfig = ''
      nix-cache.home.5kw.li {
        encode zstd
        reverse_proxy localhost:5000
      }
    '';
  };

  networking.firewall.interfaces."nm-home".allowedTCPPorts = [ 80 443 5000 ];

  system.stateVersion = "20.09";
}
