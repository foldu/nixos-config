{ pkgs, ... }:
{
  programs.fish = {
    enable = true;
    shellAbbrs = {
      rm = "rm -iv";
      mv = "mv -iv";
      cp = "cp -iv";
    };
    plugins = [
      {
        name = "tide";
        src = pkgs.fetchFromGitHub {
          owner = "IlanCosman";
          repo = "tide";
          rev = "44c521ab292f0eb659a9e2e1b6f83f5f0595fcbd";
          hash = "sha256-85iU1QzcZmZYGhK30/ZaKwJNLTsx+j3w6St8bFiQWxc=";
        };
      }
    ];
  };

  programs.zoxide = {
    enable = true;
  };
}
