{ ... }:
{
  programs.beets = {
    enable = false;
    settings = {
      directory = "/run/media/beets-lib";
      library = "~/.local/share/beets/library.db";
      plugins = [
        "lastgenre"
        "fetchart"
        "ftintitle"
      ];
    };
  };
}
