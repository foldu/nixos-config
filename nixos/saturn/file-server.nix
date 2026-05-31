{ config, ... }:
{
  users.users.Luser.isNormalUser = true;
  users.users.home-assistant = {
    isSystemUser = true;
    group = "home-assistant";
  };
  users.groups.home-assistant = { };

  services.samba = {
    enable = true;

    openFirewall = true;

    settings = {
      global = {

        # allow only local subnet
        "hosts allow" = "192.168.8.0/24 172.25.74.0/24 localhost";
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
        path = "/srv/media/fast/windows-share";
        browseable = "yes";
        "valid users" = "Luser barnabas";
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
        path = "/srv/media/fast/torrents";
        browseable = "yes";
        "valid users" = config.users.users.barnabas.name;
        "force user" = config.users.users.barnabas.name;
        public = "no";
        writeable = "yes";
      };

      other = {
        path = "/srv/media/blub/data/other";
        browseable = "yes";
        "valid users" = config.users.users.barnabas.name;
        "force user" = config.users.users.barnabas.name;
        public = "no";
        writeable = "yes";
      };

      dump = {
        path = "/srv/media/fast/dump";
        browseable = "yes";
        "valid users" = config.users.users.barnabas.name;
        "force user" = config.users.users.barnabas.name;
        public = "no";
        writeable = "yes";
      };

      backups_home-assistant = {
        path = "/srv/media/backups/home-assistant";
        browseable = "yes";
        "valid users" = "home-assistant";
        "force user" = "home-assistant";
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
}
