{ ... }:
{
  programs.firefox = {
    enable = true;
    policies = {
      DisableAppUpdate = true;
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisableFirefoxAccounts = false;
      PasswordManagerEnabled = false;
      NetworkPrediction = false;
      DisablePocket = true;
    };
    profiles."default" = {
      isDefault = true;
      extraConfig = (builtins.readFile ./betterfox.js) + ''
        // don't auto enable picture in picture when switching tabs (annoying on TWMs)
        user_pref("media.videocontrols.picture-in-picture.enable-when-switching-tabs.enabled", false);

        user_pref("browser.contentblocking.category", "strict");

        // use my own syncserver
        user_pref("identity.fxaccounts.enabled", true);
        user_pref("identity.sync.tokenserver.uri", "https://ffsync.home.5kw.li/1.0/sync/1.5");

        // do not turn on DOH and don't let mozarella enable it
        user_pref("network.trr.mode", 5);

        // don't clear entire history on shutdown
        user_pref("privacy.clearOnShutdown.downloads", false);
        user_pref("privacy.clearOnShutdown.history", false);

        // I dislike being flashbanged so just break resistFingerprinting
        user_pref("privacy.fingerprintingProtection", true);
        user_pref("privacy.fingerprintingProtection.overrides", "+AllTargets,-CSSPrefersColorScheme");
        user_pref("privacy.resistFingerprinting", false);

        // don't sync things I don't want to sync
        user_pref("services.sync.engine.history", false);
        user_pref("services.sync.engine.tabs", false);
        user_pref("services.sync.engine.workspaces", true);

        // use vertical tabs
        user_pref("sidebar.verticalTabs", true);

        // for gnome theme https://github.com/rafaelmardojai/firefox-gnome-theme
        user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
        user_pref("widget.gtk.rounded-bottom-corners.enabled", true);
        user_pref("svg.context-properties.content.enabled", true);
        user_pref("browser.theme.dark-private-windows", false);
        user_pref("browser.uidensity", 0);
      '';
    };
  };
}
