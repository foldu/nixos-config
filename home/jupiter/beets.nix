{ ... }:
{
  programs.beets = {
    enable = true;
    settings = {
      directory = "/run/media/barnabas/music";
      library = "~/.local/share/beets/library.db";
      plugins = [
        "lastgenre"
        "fetchart"
        "ftintitle"
      ];
    };
  };
}
