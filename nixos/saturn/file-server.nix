{ config, lib, pkgs, home-network, ... }: {
  users.users.wangblows.isNormalUser = true;
  services.samba = {
    enable = true;

    openFirewall = true;

    extraConfig = ''
      # allow only local subnet
      hosts allow = 10.20.30.0/24 192.168.1.0/24 localhost
      hosts deny = 0.0.0.0/0

      min protocol = SMB3

      guest account = nobody
      map to guest = bad user

      # enable encryption
      smb encrypt = desired

      # disable printer sharing so samba doesn't spam journald
      load printers = no
      printing = bsd
      printcap name = /dev/null
      disable spoolss = yes
      show add printer wizard = no
    '';

    shares.trash = {
      path = "/srv/media/main/smb";
      browseable = "yes";
      "valid users" = config.users.users.wangblows.name;
      "force user" = config.users.users.barnabas.name;
      public = "no";
      writeable = "yes";
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/nfs 755 barnabas users"
    "z /srv/nfs 755 barnabas users"
  ];

  fileSystems =
    let
      bind = mount: {
        device = mount;
        fsType = "none";
        options = [ "bind" "defaults" "nofail" "x-systemd.requires=zfs-mount.service" ];
      };
    in
    {
      "/srv/nfs/torrents" = bind "/srv/media/nvme1/data/torrents";
      "/srv/nfs/videos" = bind "/srv/media/main/vid";
      "/srv/nfs/cache" = bind "/srv/media/cia/cache";
      "/srv/nfs/img" = bind "/srv/media/cia/data/img";
      "/srv/nfs/music" = bind "/srv/media/cia/data/beets-lib";
      "/srv/nfs/smb" = bind "/srv/media/main/smb";
      "/srv/nfs/other" = bind "/srv/media/main/other";
    };

  services.nfs.server = {
    enable = true;
    # NOTE: async doesn't commit on every client write but massively speeds up write perf
    exports = ''
      /srv/nfs ${home-network.virtual-network}(rw,no_subtree_check,async,crossmnt,fsid=0)
      /srv/nfs/torrents ${home-network.virtual-network}(rw,no_subtree_check,async,all_squash,anonuid=${toString config.users.users.transmission.uid})
      /srv/nfs/videos ${home-network.virtual-network}(rw,no_subtree_check,async)
      /srv/nfs/cache ${home-network.virtual-network}(rw,no_subtree_check,async)
      /srv/nfs/img ${home-network.virtual-network}(rw,no_subtree_check,async)
      /srv/nfs/music ${home-network.virtual-network}(rw,no_subtree_check,async)
      /srv/nfs/smb ${home-network.virtual-network}(rw,no_subtree_check,async)
      /srv/nfs/other ${home-network.virtual-network}(rw,no_subtree_check,async)
    '';
    extraNfsdConfig = ''
      vers3=no
    '';
  };

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 2049 ];
}
