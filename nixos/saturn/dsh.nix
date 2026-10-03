{
  config,
  pkgs,
  ...
}:
let
  port = 3080;
  domain = "dsh.home.5kw.li";
in
{
  # `dsh web` only ever binds loopback (it rejects --host 0.0.0.0), so Caddy is
  # the only way in. Each start mints a fresh token and prints the URL carrying
  # it: `journalctl -u dsh -n1 --output=cat` for the first visit.
  systemd.services.dsh = {
    description = "dsh web GUI";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    # the agent should shell out to the same tools a login session finds
    path = [ config.system.path ];
    environment = {
      HOME = "/home/barnabas";
      DSH_HOME = "/home/barnabas/.dsh";
    };
    serviceConfig = {
      ExecStart = "${pkgs.dsh}/bin/dsh web --no-open --port ${toString port} --trusted-host ${domain}";
      User = "barnabas";
      WorkingDirectory = "/home/barnabas";
      Restart = "always";
      RestartSec = 5;
    };
  };

  services.caddy.virtualHosts.${domain}.extraConfig = ''
    reverse_proxy localhost:${toString port}
  '';
}
