{ config, lib, pkgs, ... }: {
  programs.firefox = {
    enable = true;
    profiles =
      let
        genericProfile = {
          userChrome = lib.readFile ../../config/firefox/userChrome.css;
          settings = {
            # turn off all(hopefully) telemetry
            "browser.newtabpage.activity-stream.feeds.telemetry" = false;
            "browser.newtabpage.activity-stream.telemetry.structuredIngestion.endpoint" = "";
            "browser.ping-centre.telemetry" = false;
            "browser.tabs.crashReporting.sendReport" = false;
            "datareporting.healthreport.service.enabled" = false;
            "datareporting.healthreport.uploadEnabled" = false;
            "datareporting.policy.dataSubmissionEnabled" = false;
            "devtools.onboarding.telemetry.logged" = false;
            "security.protectionspopup.recordEventTelemetry" = false;
            "toolkit.coverage.enabled" = false;
            "toolkit.coverage.enabled" = true;
            "toolkit.coverage.opt-out" = true;
            "toolkit.telemetry.bhrPing.enabled" = false;
            "toolkit.telemetry.enabled" = false;
            "toolkit.telemetry.reportingpolicy.firstRun" = false;
            "toolkit.telemetry.server" = "";
            "toolkit.telemetry.shutdownPingSender.enabled" = false;
            "toolkit.telemetry.unified" = false;
            "toolkit.telemetry.updatePing.enabled" = false;

            # do not load random things I didn't even click on
            "network.dns.disablePrefetch" = true;
            "network.predictor.enable-prefetch" = false;
            "network.prefetch-next" = false;

            # disable logging of search queries and sending them to third parties
            # FIXME: is this the correct key?
            "browser.urlbar.suggest.quicksuggest.sponsored.enable" = false;

            # disable American state propaganda in new tab
            "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
            "browser.newtabpage.activity-stream.discoverystream.enabled" = false;

            # disable ads in new tab
            "browser.newtabpage.activity-stream.showSponsored" = false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
            "browser.newtabpage.activity-stream.feeds.snippets" = false;

            # false by default, but set in case Google orders Mozilla to enable it by default
            "browser.send_pings" = false;

            # pocket will never be succesfull just stop
            "extensions.pocket.enabled" = false;

            # disable useless(for me) apis that could be used for fingerprinting
            "dom.battery.enabled" = false;
            "dom.enable_performance" = false;
            "dom.enable_resource_timing" = false;
            "dom.webaudio.enabled" = false;
            "webgl.disabled" = true;

            # absolutely nobody cares about dnt
            "privacy.donottrackheader.enabled" = false;

            # enable userChrome.css
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

            # no
            "app.normandy.enabled" = false;
            "app.shield.optoutstudies.enabled" = false;

            # disable pdf scripts
            "pdfjs.enableScripting" = false;
          };
        };
      in
      {
        "normal" = genericProfile // {
          id = 0;
          isDefault = true;
        };
        "backup" = genericProfile // { id = 1; };
      };
  };
}
