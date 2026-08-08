{ pkgs, config, inputs, ... }:
let
  port = 3920;
  shareDir = "/srv/syncthing-share";
  filesGroup = "fileshare";
in
{
  imports = [ inputs.copyparty.nixosModules.default ];

  # syncthing and copyparty need ot be one group to make this share thing work
  users.groups.${filesGroup} = { };
  users.users.syncthing.extraGroups = [ filesGroup ];
  users.users.copyparty.extraGroups = [ filesGroup ];

  systemd.tmpfiles.rules = [
    "d ${shareDir} 2770 root ${filesGroup}"
    "d ${shareDir}/public 2770 root ${filesGroup}"
  ];

  services.syncthing = {
    enable = true;
    settings = {
      options = {
        # home hosts dial in explicitly; nothing to announce or discover
        listenAddresses = [ "tcp://0.0.0.0:22000" ];
        globalAnnounceEnabled = false;
        localAnnounceEnabled = false;
      };
      devices = {
        jupiter = {
          id = "O7RPI7X-O7EEEJO-TH55KF5-64PE6MS-RPFJZ5B-LIA2ZEW-GJVBCHS-76W54AP";
          dynamic = false; # inbound only; home hosts connect to us
        };
        venus = {
          id = "7QLRH3I-32ELROX-SSYZXEI-BAZYYDW-AA5ASUJ-RVGY4EG-KDYT66K-XFMPVQW";
          dynamic = false;
        };
      };
      folders = {
        syncthing-share = {
          path = shareDir;
          devices = [ "jupiter" "venus" ];
        };
      };
    };
  };

  # syncthing sync port only (replaces openDefaultPorts: no UDP discovery ports)
  networking.firewall.allowedTCPPorts = [ 22000 ];

  # password for copyparty webdav
  sops.secrets."copyparty/password" = {
    owner = "copyparty";
    mode = "0400";
  };

  services.copyparty = {
    enable = true;
    settings = {
      i = "127.0.0.1";
      p = port;
      no-reload = true;
      hist = "/var/cache/copyparty";
    };
    package = pkgs.copyparty-min;
    accounts.barnabas.passwordFile = config.sops.secrets."copyparty/password".path;
    volumes = {
      # whole share: barnabas only (full perms). No anon access.
      "/" = {
        path = shareDir;
        access = { rwmd = [ "barnabas" ]; };
      };
      # anon r-only access to /public
      "/public" = {
        path = "${shareDir}/public";
        access = {
          r = "*";
          rwmd = [ "barnabas" ];
        };
      };
    };
  };

  services.caddy.virtualHosts."cloud.5kw.li".extraConfig = ''
    encode zstd gzip
    reverse_proxy 127.0.0.1:${toString port}
  '';
}
