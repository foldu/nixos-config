{ config, lib, pkgs, ... }: {
  programs.firefox = {
    enable = true;
    profiles =
      let
        genericProfile = {
          userChrome = lib.readFile ../../config/firefox/userChrome.css;
          settings = {
            # turn off all(hopefully) telemetry
            "toolkit.telemetry.enabled" = false;
            "browser.newtabpage.activity-stream.telemetry.structuredIngestion.endpoint" = "";
            "toolkit.telemetry.server" = "";
            "toolkit.telemetry.shutdownPingSender.enabled" = false;
            "toolkit.telemetry.updatePing.enabled" = false;
            "datareporting.healthreport.uploadEnabled" = false;
            "datareporting.healthreport.service.enabled" = false;
            "toolkit.coverage.enabled" = false;

            # do not load random things I didn't even click on
            "network.dns.disablePrefetch" = true;
            "network.predictor.enable-prefetch" = false;
            "network.prefetch-next" = false;

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
