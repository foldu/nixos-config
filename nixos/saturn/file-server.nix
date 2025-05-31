{ config, home-network, ... }:
{
  users.users.Luser.isNormalUser = true;
  services.samba = {
    enable = true;

    openFirewall = true;

    settings = {
      global = {

        # allow only local subnet
        "hosts allow" = "192.168.8.0/24 100.64.0.0/24 localhost";
        "hosts deny" = "0.0.0.0/0";

        "min protocol" = "SMB3";

        "guest account" = "nobody";
        "map to guest" = "bad user";

        # disable encryption for FAST
        "smb encrypt" = "no";

        # disable printer sharing so samba doesn't spam journald
        "load printers" = "no";
        "printing" = "bsd";
        "printcap name" = "/dev/null";
        "disable spoolss" = "yes";
        "show add printer wizard" = "no";

        # don't map the stupid windows bits
        "map archive" = "no";
        "map system" = "no";
        "map hidden" = "no";
        "unix extensions" = "no";

        "mangled names" = "no";
        "dos charset" = "CP850";
        "unix charset" = "UTF-8";
      };

      trash = {
        # allow executing files even without +x perm
        "acl allow execute always" = "yes";
        path = "/srv/media/nvme1/data/windows";
        browseable = "yes";
        "valid users" = "Luser";
        "force user" = config.users.users.barnabas.name;
        public = "no";
        writeable = "yes";
      };

      music = {
        path = "/srv/media/blub/data/music";
        browseable = "yes";
        "valid users" = config.users.users.barnabas.name;
        "force user" = config.users.users.barnabas.name;
        public = "no";
        writeable = "yes";
      };

      torrents = {
        path = "/srv/media/nvme1/data/torrents";
        browseable = "yes";
        "valid users" = config.users.users.barnabas.name;
        "force user" = config.users.users.barnabas.name;
        public = "no";
        writeable = "yes";
      };

      other = {
        path = "/srv/media/main/other";
        browseable = "yes";
        "valid users" = config.users.users.barnabas.name;
        "force user" = config.users.users.barnabas.name;
        public = "no";
        writeable = "yes";
      };

      cache = {
        path = "/srv/media/cia/cache";
        browseable = "yes";
        "valid users" = config.users.users.barnabas.name;
        "force user" = config.users.users.barnabas.name;
        public = "no";
        writeable = "yes";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  services.avahi = {
    publish.enable = true;
    publish.userServices = true;
    # ^^ Needed to allow samba to automatically register mDNS records (without the need for an `extraServiceFile`
    nssmdns4 = true;
    # ^^ Not one hundred percent sure if this is needed- if it aint broke, don't fix it
    enable = true;
    openFirewall = true;
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
      "/srv/nfs/music" = bind "/srv/media/blub/data/music";
      "/srv/nfs/smb" = bind "/srv/media/nvme1/data/windows";
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
