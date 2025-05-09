{ ... }:
{
  programs.ghostty = {
    enable = true;
    settings = {
      clipboard-write = "allow";
      font-family = "Maple Mono NL NF CN";
      shell-integration-features = "no-cursor,sudo,title";
      theme = "Kanagawa Wave";
      keybind = [
        "ctrl+enter=unbind"
      ];
    };
  };
}
