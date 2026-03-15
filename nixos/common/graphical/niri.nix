{ inputs, pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.dms-shell
  ];
  # services.dbus.packages = with pkgs; [
  #   gcr
  #   gnome-settings-daemon
  # ];

  services.gvfs.enable = true;

  programs.dms-shell = {
    enable = true;

    systemd = {
      enable = true; # Systemd service for auto-start
      restartIfChanged = true; # Auto-restart dms.service when dms-shell changes
    };

    quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.quickshell;

    # Core features
    enableSystemMonitoring = true; # System monitoring widgets (dgop)
    enableVPN = true; # VPN management widget
    enableDynamicTheming = true; # Wallpaper-based theming (matugen)
    enableAudioWavelength = true; # Audio visualizer (cava)
    enableCalendarEvents = true; # Calendar integration (khal)
    enableClipboardPaste = true; # Pasting from the clipboard history (wtype)
  };

  programs.niri = {
    enable = true;
  };
  xdg.portal.config.niri = {
    "org.freedesktop.impl.portal.FileChooser" = "kde";
    # "org.freedesktop.impl.portal.Secret" = lib.mkForce "kwallet";
  };

  # needed for noctalia
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
}
