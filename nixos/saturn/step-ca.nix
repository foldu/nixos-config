{ config, lib, pkgs, ... }:
{
  services.step-ca = {
    enable = true;
    openFirewall = true;
    port = 4321;
    intermediatePasswordFile = "/var/secrets/step-ca/password";
    address = "0.0.0.0";
    settings = {
      dnsNames = [ "ca.home.5kw.li" ];
      root = "/var/secrets/step-ca/root_ca.crt";
      crt = "/var/secrets/step-ca/intermediate_ca.crt";
      key = "/var/secrets/step-ca/intermediate_ca.key";
      db = {
        type = "badgerV2";
        dataSource = "/var/lib/step-ca/db";
      };

      authority.provisioners = [{
        type = "ACME";
        name = "acme";
      }];
    };
  };

  users.users.step-ca = {
    extraGroups = [ "secrets" ];
    group = "step-ca";
    isSystemUser = true;
  };
  users.groups.step-ca = { };

  systemd.tmpfiles.rules = [
    "d /var/lib/step-ca 700 step-ca step-ca"
    "Z /var/lib/step-ca 700 step-ca step-ca"
  ];

  systemd.services."step-ca" = {
    serviceConfig = {
      WorkingDirectory = lib.mkForce "/var/lib/step-ca";
      Environment = lib.mkForce "Home=/var/lib/step-ca";
      User = "step-ca";
      Group = "step-ca";
      DynamicUser = lib.mkForce false;
      #SystemCallArchitectures = "native";
      #SystemCallFilter = [
      #  "@system-service"
      #  "~@privileged"
      #  "~@chown"
      #  "~@aio"
      #  "~@resources"
      #];
    };
  };
}
