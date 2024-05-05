{ ... }:
{
  programs.librewolf = {
    enable = true;
    # Enable WebGL, cookies and history
    settings = {
      "privacy.clearOnShutdown.history" = false;
      "privacy.clearOnShutdown.cookies" = false;
      "network.cookie.lifetimePolicy" = 0;
    };
  };
}
