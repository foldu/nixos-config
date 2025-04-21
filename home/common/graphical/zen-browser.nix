{ inputs, ... }:
{
  imports = [ inputs.zen-browser.homeModules.beta ];
  programs.zen-browser = {
    enable = true;
    policies = {
      DisableAppUpdate = true;
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      PasswordManagerEnabled = false;
      NetworkPrediction = false;
      DisablePocket = true;
    };
    profiles.default = {
      isDefault = true;
      settings = {
        # don't auto enable picture in picture when switching tabs (annoying on TWMs)
        "media.videocontrols.picture-in-picture.enable-when-switching-tabs.enabled" = false;
        "browser.contentblocking.category" = "strict";
        # firefox llm integration sucks and is bound to only proprietary models$$$
        "browser.ml.enable" = false;
        "identity.sync.tokenserver.uri" = "https://ffsync.home.5kw.li/1.0/sync/1.5";
        "services.sync.engine.tabs" = false;
        "services.sync.engine.history" = false;
        "services.sync.engine.workspaces" = true;
        # do not turn on DOH and don't let mozarella enable it
        "network.trr.mode" = 5;
        "zen.tab-unloader.timeout-minutes" = 40;
        "zen.tab-unloader.enabled" = true;
      };
    };
  };
}
