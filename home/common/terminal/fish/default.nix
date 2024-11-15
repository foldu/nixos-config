{ pkgs, ... }:
{

  programs.kitty.shellIntegration.mode = "no-cursor";

  programs.fish = {
    enable = true;
    shellAbbrs = {
      rm = "rm -v";
      mv = "mv -iv";
      cp = "cp -iv";
      rsync = "rsync -azvP";
    };
    plugins = [ ];
  };

  programs.zoxide = {
    enable = true;
  };
}
