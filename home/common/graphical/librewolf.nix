{ ... }:
{
  programs.librewolf = {
    enable = true;
    settings = {
      "privacy.clearOnShutdown.history" = false;
      "privacy.clearOnShutdown.cookies" = false;
      "network.cookie.lifetimePolicy" = 0;
      "identity.sync.tokenserver.uri" = "https://ffsync.home.5kw.li/1.0/sync/1.5";
      "identity.fxaccounts.enabled" = true;
      "toolkit.tabbox.switchByScrolling" = false;
    };
  };
}
