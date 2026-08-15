{
  pkgs,
  lib,
  config,
  ...
}:
# To use this module you also need to allow port 9273 either on the internet or on a vpn interface
# i.e. networking.firewall.interfaces."vpn0".allowedTCPPorts = [ 9273 ];
# Example prometheus alert rules:
# - https://github.com/Mic92/dotfiles/blob/master/nixos/eva/modules/prometheus/alert-rules.nix
let
  hasNvme = lib.any (m: m == "nvme") config.boot.initrd.availableKernelModules;

  supportsFs =
    fs:
    if builtins.isAttrs config.boot.supportedFilesystems then
      config.boot.supportedFilesystems.${fs} or false
    # FIXME: When nixos 24.05 is released, supportedFilesystems will be always an attrset
    else
      lib.any (fs2: fs2 == fs) config.boot.supportedFilesystems;

  zfsChecks = lib.optional (supportsFs "zfs") (
    pkgs.writeScript "zpool-health" ''
      #!${pkgs.gawk}/bin/awk -f
      BEGIN {
        while ("${pkgs.zfs}/bin/zpool status" | getline) {
          if ($1 ~ /pool:/) { printf "zpool_status,name=%s ", $2 }
          if ($1 ~ /state:/) {
              if ($2 == "ONLINE") printf " state=\"%s\",healthy=1,", $2; else printf " state=\"%s\",healthy=0,", $2
          }
          if ($1 ~ /errors:/) {
              if (index($2, "No")) printf "errors=0i\n"; else printf "errors=%di\n", $2
          }
        }
      }
    ''
  );

  btrfsChecks = lib.optional (supportsFs "btrfs") (
    pkgs.writeShellApplication {
      name = "telegraf-btrfs";
      runtimeInputs = [
        pkgs.btrfs-progs
        pkgs.util-linux
        pkgs.gawk
        pkgs.coreutils
        pkgs.gnused
      ];
      text = builtins.readFile ./telegraf-btrfs.sh;
    }
  );
in
{
  systemd.services.telegraf.path = lib.optional hasNvme pkgs.nvme-cli ++ [ pkgs.lm_sensors ];

  sops.secrets."telegraf/env" = { };

  services.telegraf = {
    enable = true;
    environmentFiles = [ config.sops.secrets."telegraf/env".path ];
    extraConfig = {
      agent = {
        collection_jitter = "2s";
        interval = "60s";
      };
      inputs = {
        kernel_vmstat = { };
        nginx.urls = lib.mkIf config.services.nginx.statusPage [ "http://localhost/nginx_status" ];
        smart = {
          # setuid wrapper instead of sudo: see security.wrappers.smartctl below
          path_smartctl = "/run/wrappers/bin/smartctl";
        };
        system = { };
        mem = { };
        file = [
          {
            data_format = "influx";
            file_tag = "name";
            files = [ "/var/log/telegraf/*" ];
          }
        ]
        ++ lib.optional (supportsFs "ext4") {
          name_override = "ext4_errors";
          files = [ "/sys/fs/ext4/*/errors_count" ];
          data_format = "value";
        };
        systemd_units = { };
        sensors = { };
        swap = { };
        disk.tagdrop = {
          fstype = [
            "tmpfs"
            "ramfs"
            "devtmpfs"
            "devfs"
            "iso9660"
            "overlay"
            "aufs"
            "squashfs"
          ];
          device = [
            "rpc_pipefs"
            "lxcfs"
            "nsfs"
            "borgfs"
          ];
        };
        diskio = { };
        zfs = {
          poolMetrics = true;
        };
        # only add exec input on hosts with actual commands (zpool/btrfs health);
        # an exec input with no commands makes telegraf refuse the config
      }
      // lib.optionalAttrs (zfsChecks != [ ] || btrfsChecks != [ ]) {
        exec = [
          {
            # writeShellApplication wraps the script in bin/<name>; writeScript
            # produces the script at the top level, so normalize both to the
            # actual executable path
            commands = zfsChecks ++ (map (c: "${c}/bin/telegraf-btrfs") btrfsChecks);
            data_format = "influx";
          }
        ];
      };
      outputs.influxdb_v2 = {
        urls = [ "https://metrics.home.5kw.li" ];
        http_headers = {
          Authorization = "Bearer $VM_AUTH_TOKEN";
        };
        organization = "";
        bucket = "";
      };
    };
  };
  # smartctl needs root for device access. Wrapping it through sudo would
  # spam the journal every collection interval with pam_unix session
  # opened/closed + COMMAND lines (sudo-rs has no !syslog support yet, see
  # https://github.com/trifectatechfoundation/sudo-rs/issues/1181), and it
  # also collides with sudo-rs' execWheelOnly = true (wrapper is 4750
  # root:wheel). Instead, give smartctl its own setuid wrapper, executable
  # only by the telegraf group — no sudo, no PAM, no journal spam.
  security.wrappers.smartctl = {
    owner = "root";
    group = "telegraf";
    setuid = true;
    permissions = "u+rx,g+x"; # 4750 root:telegraf
    source = "${pkgs.smartmontools}/bin/smartctl";
  };

  # create dummy file to avoid telegraf errors
  systemd.tmpfiles.rules = [ "f /var/log/telegraf/dummy 0444 root root - -" ];
}
