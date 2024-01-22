{ config, pkgs, lib, ... }:
let
  guestAccountDir = "/var/lib/nitter-guest";
  guestAccountPath = "${guestAccountDir}/guest_accounts.jsonl";
  update-nitter-guest-accounts = pkgs.writeShellApplication {
    name = "update-nitter-guest-accounts";
    runtimeInputs = [ pkgs.jq pkgs.curl ];
    text = builtins.readFile ./update_guest_account.sh;
  };
in
{
  systemd.tmpfiles.rules = [
    "d ${guestAccountDir} 755 root root"
  ];

  systemd.services.nitter-refresh-guest-accounts = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = (lib.getExe update-nitter-guest-accounts);
    };
    environment = {
      GUEST_ACCOUNT_PATH = guestAccountPath;
    };
  };

  systemd.timers.nitter-refresh-guest-accounts = {
    enable = true;
    timerConfig.OnCalendar = "weekly";
    wantedBy = [ "timers.target" ];
  };

  services.nitter = {
    enable = true;
    guestAccounts = guestAccountPath;
    server = {
      hostname = "nitter.5kw.li";
      port = 3456;
    };
    config.proxy = "";
  };

  services.caddy.extraConfig = ''
    nitter.home.5kw.li {
      reverse_proxy localhost:${toString config.services.nitter.server.port}
    }
  '';
}
