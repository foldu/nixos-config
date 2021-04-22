{ config, lib, pkgs, ... }:
let
  port = 4321;
in
{
  networking.firewall.allowedTCPPorts = [ port ];

  virtualisation.oci-containers.containers = {
    step-ca = {
      image = "smallstep/step-ca:0.15.6";
      volumes = [
        "/var/lib/step:/home/step"
        "/etc/hosts:/etc/hosts:ro"
      ];
      ports = [
        "${toString port}:${toString port}"
      ];
    };
  };
}
