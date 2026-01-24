{ pkgs, ... }:
let
  betterfox = pkgs.fetchFromGitHub {
    owner = "yokoffing";
    repo = "Betterfox";
    rev = "310cbdee6ca20eb881749a559cb572ce9272a981";
    sha256 = "sha256-D2MIFdYMS3xrfO2vDYjCmC3Ah96jg5XUzvwMX3xJQBo=";
  };
  betterfoxUserJs = builtins.readFile "${betterfox}/user.js";
  additionalSettings = ''
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

    // always use the desktop portal file picker instead of the shitty gtk3 one
    user_pref("widget.use-xdg-desktop-portal.file-picker", 1);
    // always use desktop portal for opening files
    user_pref("widget.use-xdg-desktop-portal.open-uri", 1);

    // PREF: disable login manager
    user_pref("signon.rememberSignons", false);

    // PREF: disable address and credit card manager
    user_pref("extensions.formautofill.addresses.enabled", false);
    user_pref("extensions.formautofill.creditCards.enabled", false);

    // PREF: do not allow embedded tweets, Instagram, Reddit, and Tiktok posts
    user_pref("urlclassifier.trackingSkipURLs", "");
    user_pref("urlclassifier.features.socialtracking.skipURLs", "");

    // PREF: hide site shortcut thumbnails on New Tab page
    user_pref("browser.newtabpage.activity-stream.feeds.topsites", false);

    // PREF: hide weather on New Tab page
    user_pref("browser.newtabpage.activity-stream.showWeather", false);

    // PREF: hide dropdown suggestions when clicking on the address bar
    user_pref("browser.urlbar.suggest.topsites", false);

    // PREF: enforce certificate pinning
    // [ERROR] MOZILLA_PKIX_ERROR_KEY_PINNING_FAILURE
    // 1 = allow user MiTM (such as your antivirus) (default)
    // 2 = strict
    user_pref("security.cert_pinning.enforcement_level", 2);

    user_pref("privacy.clearOnShutdown_v2.cache", true);

    // PREF: after crashes or restarts, do not save extra session data
    // such as form content, scrollbar positions, and POST data
    user_pref("browser.sessionstore.privacy_level", 2);

    // PREF: disable all DRM content
    user_pref("media.eme.enabled", false);

    // PREF: hide the UI setting; this also disables the DRM prompt (optional)
    user_pref("browser.eme.ui.enabled", false);

    user_pref("apz.overscroll.enabled", true); // DEFAULT NON-LINUX
    user_pref("general.smoothScroll", true); // DEFAULT
    user_pref("general.smoothScroll.msdPhysics.enabled", true);
    user_pref("mousewheel.default.delta_multiplier_y", 300); // 250-400; adjust this number to your liking
  '';
  genericSettings = betterfoxUserJs + additionalSettings;
in
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
      DisableFeedbackCommands = true;
      DisableSetDesktopBackground = true;
      DisableDeveloperTools = false;
      DontCheckDefaultBrowser = true;
    };
    profiles = {
      "default" = {
        id = 0;
        extraConfig = genericSettings;
      };

      "clean" = {
        id = 1;
        extraConfig = genericSettings;
      };

      "other" = {
        id = 2;
        extraConfig = genericSettings;
      };
    };
  };
}
