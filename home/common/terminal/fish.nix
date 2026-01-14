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
      bind alt-backspace backward-kill-word
      bind ctrl-w backward-kill-bigword
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
      # fixes broken prompt character https://github.com/IlanCosman/tide/pull/626
      _tide_item_character = ''
        test $_tide_status = 0 && set_color $tide_character_color || set_color $tide_character_color_failure

        set -q add_prefix || echo -ns ' '

        test -n "$fish_key_bindings" && test "$fish_key_bindings" != fish_default_key_bindings &&
            switch $fish_bind_mode
                case insert
                    echo -ns $tide_character_icon
                case default
                    echo -ns $tide_character_vi_icon_default
                case replace replace_one
                    echo -ns $tide_character_vi_icon_replace
                case visual
                    echo -ns $tide_character_vi_icon_visual
            end ||
            echo -ns $tide_character_icon
      '';
    };
    plugins = [
      {
        name = "tide";
        src = pkgs.fetchFromGitHub {
          owner = "IlanCosman";
          repo = "tide";
          rev = "fcda500d2c2996e25456fb46cd1a5532b3157b16";
          sha256 = "sha256-dzYEYC1bYP0rWpmz0fmBFwskxWYuKBMTssMELXXz5H0=";
        };
      }
    ];
  };
}
