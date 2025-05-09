{ ... }:
{
  programs.ghostty = {
    enable = true;
    settings = {
      clipboard-write = "allow";
      font-family = "Maple Mono";
      shell-integration-features = "no-cursor,sudo,title";
      theme = "Kanagawa Wave";
      keybind = [
        "ctrl+enter=unbind"
      ];
    };
  };
}
