{ config, lib, pkgs, ... }:
# mostly stolen from https://github.com/Mic92/dotfiles/blob/77f0fc3617dcb823ef6051fa66a344ee38aed08a/nixos/eve/modules/drone/server.nix
with lib;

let
  cfg = config.services.drone-server;
in
{
  options = {
    services.drone-server = {
      enable = mkEnableOption "Enable the drone server";
      environmentFile = mkOption {
        type = types.path;
        default = "/var/secrets/drone-server.env";
        description = ''
          Environment configuration for drone server
          WARNING: If you use ./my_environment it will be world readable in the nix store
        '';
      };
      host = mkOption {
        type = types.str;
        description = ''
          External hostname of your drone server instance
        '';
        default = config.networking.hostName;
      };
      proto = mkOption {
        type = types.enum [ "http" "https" ];
        description = ''
          Protocol used to access your drone instance
        '';
        default = "http";
      };
      databaseCreateLocally = mkOption {
        type = types.bool;
        description = ''
          Create a local postgresql database and communicate over unix socket
        '';
        default = true;
      };
      adminName = mkOption {
        type = types.str;
        default = "drone";
        description = ''
          Name of admin account
        '';
      };
      port = mkOption {
        type = types.port;
        description = ''
          Port drone-server listens on
        '';
        default = 3030;
      };
      user = mkOption {
        type = types.str;
        description = ''
          Drone server user
        '';
        default = "droneserver";
      };
      group = mkOption {
        type = types.str;
        description = ''
          Drone server group
        '';
        default = "droneserver";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.databaseCreateLocally;
        message = "Non-local databases currently not supported";
      }
    ];

    systemd.services.drone-server = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        EnvironmentFile = [
          cfg.environmentFile
        ];
        Environment = [
          "DRONE_DATABASE_DATASOURCE=postgres:///droneserver?host=/run/postgresql"
          "DRONE_DATABASE_DRIVER=postgres"
          "DRONE_SERVER_PROTO=${cfg.proto}"
          "DRONE_SERVER_HOST=${cfg.host}"
          "DRONE_SERVER_PORT=:${toString cfg.port}"
          "DRONE_USER_CREATE=username:${cfg.adminName},admin:true"
        ];
        ExecStart = "${pkgs.drone}/bin/drone-server";
        User = cfg.user;
        Group = cfg.group;
        CapabilityBoundingSet = "";
        DeviceAllow = "";
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectDevices = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "full";
        ProtectProc = "noaccess";
        RemoveIpc = true;
        RestrictRealtime = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
        RestrictNamespaces = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
          "~@chown"
          "~@aio"
          "~@resources"
        ];
      };
    };


    services.postgresql = lib.mkIf cfg.databaseCreateLocally {
      ensureDatabases = [ cfg.user ];
      ensureUsers = [{
        name = cfg.user;
        ensurePermissions = {
          "DATABASE ${cfg.user}" = "ALL PRIVILEGES";
        };
      }];
    };

    users.users.${cfg.user} = {
      isSystemUser = true;
      createHome = true;
      group = cfg.group;
    };
    users.groups.${cfg.group} = { };
  };
}
