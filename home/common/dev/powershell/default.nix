{ pkgs, ... }:
{
  home.packages = with pkgs; [
    powershell
    powershell-editor-services
  ];
  xdg.configFile."powershell/Microsoft.PowerShell_profile.ps1".source = ./profile.ps1;

  systemd.user.services.powershell-modules-update = {
    Unit = {
      After = "network.target";
    };
    Service = {
      ExecStart = "${pkgs.powershell}/bin/pwsh -i -c Update-Module";
    };
  };

  systemd.user.timers.powershell-modules-update = {
    Unit.description = "Update powershell modules";
    Timer = {
      Unit = "update-powershell-modules";
      Persistent = true;
      OnCalendar = "weekly";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
