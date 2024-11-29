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
      rsync = "rsync -azv --info=progress2 --filter=':- .gitignore'";
      sm = "src-manage";
      gr = "cd (git rev-parse --show-toplevel)";
    };
    interactiveShellInit = ''
      set -g fish_greeting
    '';
    shellAliases = {
      ls = "ls --hyperlink=auto --color=auto";
    };
    functions = {
      tide_setup = ''
        tide configure --auto --style=Lean --prompt_colors='16 colors' --show_time='24-hour format' --lean_prompt_height='One line' --prompt_spacing=Compact --icons='Few icons' --transient=No
        set -U tide_character_icon "\$"
        set -U tide_left_prompt_items context pwd git character
        set -U tide_right_prompt_items status cmd_duration jobs direnv bun node python rustc java php pulumi ruby go gcloud kubectl distrobox toolbox terraform aws nix_shell crystal elixir zig time
      '';
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
