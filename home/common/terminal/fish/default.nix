{ pkgs, ... }:
{
  programs.fish = {
    enable = true;
    shellAbbrs = {
      rm = "rm -iv";
      mv = "mv -iv";
      cp = "cp -iv";
    };
    plugins = [ ];
  };

  programs.zoxide = {
    enable = true;
  };
}
