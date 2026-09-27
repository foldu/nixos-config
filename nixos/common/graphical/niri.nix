{
  inputs,
  pkgs,
  ...
}:
{
  services.gvfs.enable = true;

  i18n.inputMethod = {
    enable = true;
    type = "ibus";
  };

  programs.dms-shell = {
    enable = true;

    systemd = {
      enable = true; # Systemd service for auto-start
      restartIfChanged = true; # Auto-restart dms.service when dms-shell changes
    };

    quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.quickshell;
  };

  programs.niri = {
    enable = true;
  };

  # needed for noctalia
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;

  # dank material shell already has a polkit agent
}
