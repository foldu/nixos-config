{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.drone-exec-runner;
in
{
  options = {
    services.drone-exec-runner = {
      enable = mkEnableOption "Drone exec runner (DNOT' USE THIS ON UNTRUSTED REPOS)";
      rpcHost = mkOption {
        type = types.str;
        default = "127.0.0.1:${toString config.services.drone-server.port}";
        description = ''
          Drone rpc host
        '';
      };
      rpcProto = mkOption {
        type = types.enum [ "http" "https" ];
        default = "http";
        description = ''
          Rpc protocol
        '';
      };
      runnerCapacity = mkOption {
        type = types.ints.positive;
        default = 10;
        description = ''
          Runner capacity
        '';
      };
      environmentFile = mkOption {
        type = types.path;
        default = "/var/secrets/drone-exec-runner.env";
        description = ''
          Environment file with credentials
        '';
      };
      user = mkOption {
        type = types.str;
        description = ''
          Drone server user
        '';
        default = "drone-exec-runner";
      };
      group = mkOption {
        type = types.str;
        description = ''
          Drone server group
        '';
        default = "drone-exec-runner";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.drone-exec-runner = {
      wantedBy = [ "multi-user.target" ];
      # might break deployment
      restartIfChanged = false;
      confinement.enable = true;
      confinement.packages = with pkgs; [
        git
        gnutar
        bash
        nixUnstable
        gzip
      ];
      path = with pkgs; [
        git
        gnutar
        bash
        nixUnstable
        gzip
      ];
      serviceConfig = {
        Environment = [
          "DRONE_RUNNER_CAPACITY=${toString cfg.runnerCapacity}"
          "CLIENT_DRONE_RPC_HOST=${cfg.rpcHost}"
          "NIX_REMOTE=daemon"
          "PAGER=cat"
        ];
        EnvironmentFile = [
          cfg.environmentFile
        ];
        ExecStart = "${pkgs.drone-runner-exec}/bin/drone-runner-exec";
        User = cfg.user;
        Group = cfg.group;
        BindPaths = [
          "/nix/var/nix/daemon-socket/socket"
          "/run/nscd/socket"
          "/var/lib/drone"
        ];
        BindReadOnlyPaths = [
          "/etc/passwd:/etc/passwd"
          "/etc/group:/etc/group"
          "/nix/var/nix/profiles/system/etc/nix:/etc/nix"
          "${config.environment.etc."ssl/certs/ca-certificates.crt".source}:/etc/ssl/certs/ca-certificates.crt"
          "/etc/machine-id"
          # channels are dynamic paths in the nix store, therefore we need to bind mount the whole thing
          "/nix/"
        ];
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

    systemd.tmpfiles.rules = [
      "d /var/lib/drone 700 ${cfg.user} ${cfg.group}"
      "Z /var/lib/drone 700 ${cfg.user} ${cfg.group}"
    ];

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
    };
    users.groups.${cfg.group} = { };
  };
}
