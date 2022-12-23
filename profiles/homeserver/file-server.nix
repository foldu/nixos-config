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

  services.nfs.server = {
    enable = true;
    statdPort = 2200;
    lockdPort = 2201;
    mountdPort = 2202;
    # NOTE: async doesn't commit on every client write but massively speeds up write perf
    exports = ''
      /srv/media/aux/downloads ${home-network.virtual-network}(rw,async,all_squash,anonuid=${toString config.users.users.transmission.uid})
      /srv/media/main/vid ${home-network.virtual-network}(rw,async)
      /srv/media/cia/cache ${home-network.virtual-network}(rw,async)
      /srv/media/cia/data/img ${home-network.virtual-network}(rw,async)
      /srv/media/cia/data/music ${home-network.virtual-network}(rw,async)
      /srv/media/cia/data/beets-lib ${home-network.virtual-network}(rw,async)
      /srv/media/main/smb ${home-network.virtual-network}(rw,async)
      /srv/media/main/other ${home-network.virtual-network}(rw,async)
    '';
  };

  # TODO: only allow nfs on nebula interface
  networking.firewall = {
    allowedTCPPorts = [
      # nfs
      config.services.nfs.server.statdPort
      config.services.nfs.server.lockdPort
      config.services.nfs.server.mountdPort
      2049
      111
    ];
    allowedUDPPorts = [
      # nfs
      config.services.nfs.server.statdPort
      config.services.nfs.server.lockdPort
      config.services.nfs.server.mountdPort
      111
    ];
  };
}
