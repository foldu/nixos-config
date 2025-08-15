{ ... }:
{
  programs.librewolf = {
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
      settings = {
        # don't auto enable picture in picture when switching tabs (annoying on TWMs)
        "media.videocontrols.picture-in-picture.enable-when-switching-tabs.enabled" = false;
        "browser.contentblocking.category" = "strict";
        # firefox llm integration sucks and is bound to only proprietary models$$$
        "browser.ml.enable" = false;
        "identity.sync.tokenserver.uri" = "https://ffsync.home.5kw.li/1.0/sync/1.5";
        "identity.fxaccounts.enabled" = true;
        "services.sync.engine.tabs" = false;
        "services.sync.engine.history" = false;
        "services.sync.engine.workspaces" = true;
        # do not turn on DOH and don't let mozarella enable it
        "network.trr.mode" = 5;

        "sidebar.verticalTabs" = true;

        # I dislike being flashbanged so just break resistFingerprinting
        "privacy.resistFingerprinting" = false;
        "privacy.fingerprintingProtection" = true;
        "privacy.fingerprintingProtection.overrides" = "+AllTargets,-CSSPrefersColorScheme";

        "privacy.clearOnShutdown.history" = false;
        "privacy.clearOnShutdown.downloads" = false;

        # for gnome theme
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "browser.uidensity" = 0;
        "svg.context-properties.content.enabled" = true;
        "browser.theme.dark-private-windows" = false;
        "widget.gtk.rounded-bottom-corners.enabled" = true;
      };
    };
  };
}
