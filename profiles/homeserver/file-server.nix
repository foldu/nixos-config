{ config, lib, pkgs, ... }: {
  users.users.wangblows.name = "wangblows";
  services.samba = {
    enable = true;

    extraConfig = ''
      # allow only local subnet
      hosts allow = 192.168.1.0/24 localhost
      hosts deny = 0.0.0.0/0

      min protocol = SMB2
      max protocol = SMB3

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

  services.nfs.server = {
    enable = true;
    statdPort = 2200;
    lockdPort = 2201;
    mountdPort = 2202;
    exports = ''
      /srv/media/aux/downloads 192.168.1.0/24(rw,all_squash,anonuid=${toString config.users.users.transmission.uid})
      /srv/media/main/vid 192.168.1.0/24(rw)
      /srv/media/cia/cache 192.168.1.0/24(rw)
      /srv/media/cia/data/img 192.168.1.0/24(rw)
      /srv/media/cia/data/music 192.168.1.0/24(rw)
      /srv/media/main/smb 192.168.1.0/24(rw)
      /srv/media/main/other 192.168.1.0/24(rw)
    '';
  };

  networking.firewall = {
    allowedTCPPorts = [
      # samba
      445
      139

      # nfs
      config.services.nfs.server.statdPort
      config.services.nfs.server.lockdPort
      config.services.nfs.server.mountdPort
      2049
    ];
    allowedUDPPorts = [
      # samba
      137
      138

      # nfs
      config.services.nfs.server.statdPort
      config.services.nfs.server.lockdPort
      config.services.nfs.server.mountdPort
    ];
  };
}
