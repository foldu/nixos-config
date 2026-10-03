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

  # dms.service is wantedBy graphical-session.target, which *every* session
  # reaches, so without this it also starts in the GDM greeter (and in a GNOME
  # session). DMS is a niri shell: it needs wlr-layer-shell, and its Type=dbus
  # readiness depends on owning org.freedesktop.Notifications - under mutter it
  # gets neither, so it burned the full 90s start timeout and restarted forever.
  # That kept the greeter's user manager alive long enough for niri to race it for
  # the DRM primary node, come up with zero outputs and show a black screen.
  systemd.user.services.dms.unitConfig.ConditionEnvironment = [ "XDG_CURRENT_DESKTOP=niri" ];

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
