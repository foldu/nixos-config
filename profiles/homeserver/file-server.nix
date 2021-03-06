{ config, lib, pkgs, home-network, ... }: {
  users.users.wangblows.isNormalUser = true;
  services.samba = {
    enable = true;

    extraConfig = ''
      # allow only local subnet
      hosts allow = 192.168.88.0/24 localhost
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
      /srv/media/aux/downloads ${home-network.network}(rw,all_squash,anonuid=${toString config.users.users.transmission.uid})
      /srv/media/main/vid ${home-network.network}(rw)
      /srv/media/cia/cache ${home-network.network}(rw)
      /srv/media/cia/data/img ${home-network.network}(rw)
      /srv/media/cia/data/music ${home-network.network}(rw)
      /srv/media/cia/data/beets-lib ${home-network.network}(rw)
      /srv/media/main/smb ${home-network.network}(rw)
      /srv/media/main/other ${home-network.network}(rw)
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
      111
    ];
    allowedUDPPorts = [
      # samba
      137
      138

      # nfs
      config.services.nfs.server.statdPort
      config.services.nfs.server.lockdPort
      config.services.nfs.server.mountdPort
      111
    ];
  };
}
