{ pkgs, inputs, ... }:
{
  imports = [
    ./telegraf.nix
  ];

  users.users.barnabas = {
    isNormalUser = true;
    uid = 1000;
    shell = pkgs.fish;
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

  environment.systemPackages = [
    inputs.home-manager.packages.${pkgs.stdenv.hostPlatform.system}.home-manager
    inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.neovim
  ];
}
