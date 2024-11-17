{ pkgs, ... }:
{
  programs.kitty.shellIntegration.mode = "no-cursor";

  programs.nix-index.enable = true;

  programs.fish = {
    enable = true;
    shellAbbrs = {
      rm = "rm -v";
      mv = "mv -iv";
      cp = "cp -iv";
      rsync = "rsync -azvP";
      sm = "src-manage";
    };
    interactiveShellInit = ''
      set -g tide_character_icon '$'
      set -g fish_greeting
    '';
    shellAliases = {
      ls = "ls --hyperlink=auto --color=auto";
    };
    plugins = [
      {
        name = "tide";
        src = pkgs.fetchFromGitHub {
          owner = "IlanCosman";
          repo = "tide";
          rev = "44c521ab292f0eb659a9e2e1b6f83f5f0595fcbd";
          sha256 = "sha256-85iU1QzcZmZYGhK30/ZaKwJNLTsx+j3w6St8bFiQWxc=";
        };
      }
    ];
  };

  programs.zoxide = {
    enable = true;
  };
}
