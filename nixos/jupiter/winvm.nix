{
  pkgs,
  ...
}:
let
  domain = "win";
  mac = "52:54:00:9f:1a:6d";
  ip = "192.168.122.50";

  # libvirt does not create its default NAT network on NixOS. A pinned MAC plus a
  # DHCP reservation is what gives the guest a stable address to ssh to.
  netXml = pkgs.writeText "libvirt-default-net.xml" ''
    <network>
      <name>default</name>
      <forward mode='nat'/>
      <bridge name='virbr0' stp='on' delay='0'/>
      <ip address='192.168.122.1' netmask='255.255.255.0'>
        <dhcp>
          <range start='192.168.122.100' end='192.168.122.199'/>
          <host mac='${mac}' name='${domain}' ip='${ip}'/>
        </dhcp>
      </ip>
    </network>
  '';
in
{
  imports = [ ../common/libvirt.nix ];

  # qcow2 on btrfs is COW on top of COW: it fragments and snapshots fight each
  # other. +C on the directory makes new images inherit nocow, and has to happen
  # before the first image exists.
  systemd.services.libvirt-image-dirs = {
    wantedBy = [ "multi-user.target" ];
    before = [ "libvirtd.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      install -d -m 0711 /var/lib/libvirt/images
      ${pkgs.e2fsprogs}/bin/chattr +C /var/lib/libvirt/images || true
    '';
  };

  systemd.services.libvirt-default-net = {
    wantedBy = [ "multi-user.target" ];
    after = [ "libvirtd.service" ];
    requires = [ "libvirtd.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # libvirt usually gets there first with a stock "default" network (the whole
      # 192.168.122.2-254 pool, no reservation), so this has to cope with the
      # network already existing:
      #   * net-define refuses to update an existing network
      #   * net-destroy succeeds even while a guest holds it, and takes that
      #     guest's link down with it -- the tap does not come back on net-start
      # so an existing network is adjusted in place with net-update instead, and
      # the pool from netXml only applies on a host where we define it first.
      ${pkgs.libvirt}/bin/virsh net-info default >/dev/null 2>&1 ||
        ${pkgs.libvirt}/bin/virsh net-define ${netXml}

      ${pkgs.libvirt}/bin/virsh net-info default | grep -qE 'Active: +yes' ||
        ${pkgs.libvirt}/bin/virsh net-start default

      # adding the same host entry twice is an error, so only when it is absent
      ${pkgs.libvirt}/bin/virsh net-dumpxml default | grep -q '${mac}' ||
        ${pkgs.libvirt}/bin/virsh net-update default add ip-dhcp-host \
          "<host mac='${mac}' name='${domain}' ip='${ip}'/>" --live --config

      ${pkgs.libvirt}/bin/virsh net-autostart default
    '';
  };

  environment.systemPackages = [
    (pkgs.winvm.override {
      inherit domain ip;
      guestMac = mac;
    })
  ];
}
