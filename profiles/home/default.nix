{ config, lib, pkgs, ... }:

let
  home-network = fromTOML (builtins.readFile ../../home-network.toml);
in
{
  imports = [
    ./netmaker-node.nix
  ];
  # does it even matter if this thing is not secret
  security.pki.certificateFiles = [ ../../home_ca.crt ];

  environment.systemPackages = with pkgs; [
    fuse
    sshfs
  ];

  nix.buildMachines = [{
    hostName = "jupiter.home.5kw.li";
    systems = [ "x86_64-linux" "aarch64-linux" ];
    # if the builder supports building for multiple architectures, 
    # replace the previous line by, e.g.,
    # systems = ["x86_64-linux" "aarch64-linux"];
    sshUser = "nixosbuilder";
    sshKey = "/home/barnabas/.ssh/nixosbuilder";
    maxJobs = 32;
    speedFactor = 1337;
    supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    mandatoryFeatures = [ ];
  }];

  nix.settings = {
    trusted-substituters = [
      "https://nix-cache.home.5kw.li"
      "https://cache.nixos.org"
    ];
    substituters = [
      "https://nix-cache.home.5kw.li"
      "https://cache.nixos.org"
      #"https://nix-cache-cache.5kw.li"
    ];
    trusted-public-keys = [ "nix-cache.home.5kw.li:QexhkxGRd2H38Nl12jeZmUNZJk+4272/xYmMcFraunk=" ];
  };

  users.users.barnabas = {
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJQ+TsvKvdWG+9KLVeg5N4y1Ce1jr/fP3ELTHVWLxZOR" ];
  };
}
