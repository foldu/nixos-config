{ config, lib, pkgs, ... }:

let
  home-network = fromTOML (builtins.readFile ../home-network.toml);
in
{
  # does it even matter if this thing is not secret
  security.pki.certificateFiles = [ ../secrets/home_ca.crt ];

  environment.systemPackages = with pkgs; [
    fuse
    sshfs
  ];

  nix.buildMachines = [{
    hostName = "jupiter.5kw.li";
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

  nix.extraOptions = ''
    substituters = https://nix-cache-cache.5kw.li
  '';

  users.users.barnabas = {
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJQ+TsvKvdWG+9KLVeg5N4y1Ce1jr/fP3ELTHVWLxZOR" ];
  };

  fileSystems = with lib; flip mapAttrs' home-network.devices (
    hostName: device:
      let
        myUser = config.users.users.barnabas;
        uid = toString myUser.uid;
      in
      {
        name = "/run/media/home/${hostName}";
        value = {
          # can't set device to ${myUser.home} because of infinite recursion
          # TODO: investigate
          device = "barnabas@${device.ip}:/home/barnabas";
          fsType = "fuse.sshfs";
          options = [
            "IdentityFile=${myUser.home}/.ssh/home"
            "IdentityAgent=/run/user/${uid}/ssh-agent"
            "noauto"
            "_netdev"
            "x-systemd.automount"
            "x-systemd.device-timeout=10"
            "idmap=user"
            "user"
            "allow_other"
            "uid=${uid}"
          ];
        };
      }
  );
}
