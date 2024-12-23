{ config, home-network, ... }:
{
  users.users.wangblows.isNormalUser = true;
  services.samba = {
    enable = true;

    openFirewall = true;

    settings = {
      global = {

        # allow only local subnet
        "hosts allow" = "192.168.8.0/24 localhost";
        "hosts deny" = "0.0.0.0/0";

        # allow executing files even without +x perm
        "acl allow execute always" = "yes";

        "min protocol" = "SMB3";

        "guest account" = "nobody";
        "map to guest" = "bad user";

        # enable encryption
        "smb encrypt" = "desired";

        # disable printer sharing so samba doesn't spam journald
        "load printers" = "no";
        "printing" = "bsd";
        "printcap name" = "/dev/null";
        "disable spoolss" = "yes";
        "show add printer wizard" = "no";
      };
    };
    # extraConfig = ''
    #   # allow only local subnet
    #   hosts allow = 10.20.30.0/24 192.168.1.0/24 localhost
    #   hosts deny = 0.0.0.0/0
    #
    #   # allow executing files even without +x perm
    #   acl allow execute always = yes
    #
    #   min protocol = SMB3
    #
    #   guest account = nobody
    #   map to guest = bad user
    #
    #   # enable encryption
    #   smb encrypt = desired
    #
    #   # disable printer sharing so samba doesn't spam journald
    #   load printers = no
    #   printing = bsd
    #   printcap name = /dev/null
    #   disable spoolss = yes
    #   show add printer wizard = no
    # '';

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
        options = [
          "bind"
          "defaults"
          "nofail"
          "x-systemd.requires=zfs-mount.service"
        ];
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

  services.nfs = {
    server = {
      enable = true;
      # NOTE: async doesn't commit on every client write but massively speeds up write perf
      exports =
        let
          mkGenericEntry = opts: "${home-network.virtual-network}(${opts}) ${home-network.network}(${opts})";
          mkEntry = mkGenericEntry "rw,no_subtree_check,async";
        in
        ''
          /srv/nfs ${mkGenericEntry "rw,no_subtree_check,async,crossmnt,fsid=0"}
          /srv/nfs/torrents ${mkGenericEntry "rw,no_subtree_check,async,all_squash,anonuid=${toString config.users.users.transmission.uid}"}
          /srv/nfs/videos ${mkEntry}
          /srv/nfs/cache  ${mkEntry}
          /srv/nfs/img    ${mkEntry}
          /srv/nfs/music  ${mkEntry}
          /srv/nfs/smb    ${mkEntry}
          /srv/nfs/other  ${mkEntry}
        '';
    };
    settings = {
      nfsd.vers3 = false;
    };
  };

  networking.firewall.allowedTCPPorts = [ 2049 ];
}
