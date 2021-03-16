{ config, lib, pkgs, ... }:

let
  home-network = fromTOML (builtins.readFile ../home-network.toml);
in
{
  services.zerotierone = {
    enable = true;
    joinNetworks = (import ../secrets).zerotierNetworks;
  };

  # does it even matter if this thing is not secret
  security.pki.certificateFiles = [ ../secrets/home_ca.crt ];

  networking.hosts = lib.flip lib.mapAttrs' home-network.devices (_: device: {
    name = device.ip;
    value = device.hosts;
  });

  environment.systemPackages = with pkgs; [
    fuse
    sshfs
  ];

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
