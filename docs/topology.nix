{
  config,
  lib,
  ...
}:
let
  inherit (config.lib.topology)
    mkInternet
    mkRouter
    mkSwitch
    mkConnection
    ;
in
{
  networks = {
    home = {
      name = "Home";
      cidrv4 = "192.168.8.0/24";
    };
    home-iot = {
      name = "Home IoT";
      cidrv4 = "192.168.10.0/24";
    };
    netbird = {
      name = "netbird mesh";
      cidrv4 = "172.25.74.0/24";
    };
  };

  nodes = {
    # networking hardware
    internet = mkInternet { connections = mkConnection "router" "wan1"; };

    router = mkRouter "Flint 2" {
      info = "GL.iNet GL-MT6000";
      interfaceGroups = [
        [
          "eth1"
          "eth2"
        ]
        [ "wan1" ]
      ];
      connections.wan1 = mkConnection "internet" "*";
      connections.eth1 = mkConnection "switch-main" "eth1";
      interfaces.eth1 = {
        addresses = [ "192.168.8.1" ];
        network = "home";
      };
    };

    switch-main = mkSwitch "Main Switch" {
      info = "TRENDnet TEG-S562 (4x2.5G ethernet + 2x10G SFP)";
      interfaceGroups = [
        [
          "eth1"
          "eth2"
          "eth3"
          "eth4"
        ]
        [
          "sfp1"
          "sfp2"
        ]
      ];
      connections.eth1 = mkConnection "router" "eth1";
      connections.sfp1 = mkConnection "sol" "vmbr0";
      connections.sfp2 = mkConnection "jupiter" "enp7s0";
    };

    # proxmox hypervisors
    sol = {
      deviceType = "server";
      name = "sol";
      hardware.info = "Main server: AMD Ryzen 3950X, 64GB RAM";
      icon = ./img/proxmox.svg;
      interfaces.vmbr0 = {
        addresses = [ "192.168.8.203" ];
        network = "home";
        physicalConnections = [ (mkConnection "switch-main" "sfp1") ];
      };
    };

    # non-nixos VMs and containers
    netbird-gw = {
      parent = "sol";
      deviceType = "server";
      name = "netbird-gw";
      guestType = "lxc";
      hardware.info = "Netbird gateway";
      interfaces = {
        eth0 = {
          type = "ethernet";
          network = "home";
        };
        wt0 = {
          type = "wireguard";
          addresses = [ "172.25.74.230" ];
          network = "netbird";
        };
      };
    };
    hass = {
      parent = "sol";
      deviceType = "server";
      name = "hass";
      guestType = "proxmox-vm";
      hardware = {
        info = "home-assistant";
      };
      icon = ./img/home-assistant.svg;
      interfaces = {
        wlp6s16 = {
          network = "home-iot";
          addresses = [ "192.168.10.212" ];
        };
        wt0 = {
          type = "wireguard";
          addresses = [ "172.25.74.192" ];
          network = "netbird";
        };
      };
    };

    # nixos hosts
    jupiter = {
      hardware.info = "Workstation: AMD Ryzen 9 9950X3D, AMD Radeon RX 9070 XT, 64GB RAM";
      interfaces = {
        enp7s0 = {
          addresses = [ "192.168.8.107" ];
          network = "home";
          physicalConnections = [ (mkConnection "switch-main" "sfp2") ];
        };
        wt0 = {
          type = "wireguard";
          addresses = [ "172.25.74.214" ];
          network = "netbird";
        };
      };
    };
    saturn = {
      parent = "sol";
      guestType = "proxmox-vm";
      hardware.info = "Fat VM that should be split up: nvidia 5060 TI, 6 disk JBOD";
      interfaces = {
        ens18 = {
          addresses = [ "192.168.8.149" ];
          network = "home";
        };
        wt0 = {
          type = "wireguard";
          addresses = [ "172.25.74.33" ];
          network = "netbird";
        };
      };
    };
    venus = {
      hardware.info = "Laptop: Framework 13, AMD Ryzen 5 7640U";
      interfaces = {
        wlan0 = {
          network = "home";
        };
        wt0 = {
          type = "wireguard";
          addresses = [ "172.25.74.166" ];
          network = "netbird";
        };
      };
    };
    ubuntu-4gb-fsn1-3 = {
      hardware.info = "Hetzner VPS";
      interfaces.eth0 = { };
    };
  };
}
