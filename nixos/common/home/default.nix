{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./telegraf.nix
    inputs.baash.nixosModules.default
  ];

  users.users.barnabas = {
    isNormalUser = true;
    uid = 1000;
    # The package, not `lib.getExe`: it carries a `shellPath`, which is how
    # NixOS resolves both this and the `/etc/shells` entry the module adds, so
    # `/etc/passwd` and `/etc/shells` name the same path and PAM's comparison
    # holds.
    shell = config.programs.baash.package;
    extraGroups = [
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      # barnabas@home from bitwarden
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHt6FyRH9+5nbAGbKyuDcjz5YzJ31xLKPJBWAjdTWbJq"
    ];
  };

  sops.defaultSopsFile = ../../../secrets/secrets.yaml;

  services.netbird.enable = true;

  # Home hosts only: on the Hetzner box this flake has to be built under qemu
  # for aarch64, which is not worth it for a shell. The module installs baash,
  # lists it in `/etc/shells` and writes `/etc/xdg/baash/config.sh`; zoxide
  # adds `z`, `zi` and the hook that records directories for them.
  programs.baash = {
    enable = true;
    zoxide.enable = true;
  };

  environment.systemPackages = [
    inputs.home-manager.packages.${pkgs.stdenv.hostPlatform.system}.home-manager
    inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.neovim
  ];
}
