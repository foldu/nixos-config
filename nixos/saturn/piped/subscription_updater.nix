{ pkgs, ... }: {
  systemd.services.piped-subscription-updater =
    let
      updater = pkgs.writeShellApplication {
        name = "piped-subscription-updater";
        runtimeInputs = with pkgs; [ jq curl ];
        text = builtins.readFile ./subscription_updater.sh;
      };
    in
    {
      after = [ "network.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${updater}/bin/piped-subscription-updater";
        RestartSec = "1minute";
        EnvironmentFile = "/var/secrets/piped-updater.env";
      };
    };

  systemd.timers.piped-subscription-updater = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "hourly";
  };
}
