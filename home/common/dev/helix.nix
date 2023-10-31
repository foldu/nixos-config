{ pkgs, config, inputs, ... }:
let
  brootConfigPath = "broot/helix-tree.hjson";
  helixOpener = inputs.nix-stuff.packages.${pkgs.system}.writeNuScript {
    name = "helix-opener";
    file = ./helix-opener.nu;
    path = [ pkgs.wezterm ];
  };
in
{
  # https://quantonganh.com/2023/08/19/turn-helix-into-ide

  xdg.configFile.${brootConfigPath} = {
    text = builtins.toJSON (config.programs.broot.settings // {
      modal = true;
      verbs = [
        {
          invocation = "edit";
          key = "enter";
          execution = "${helixOpener}/bin/helix-opener {file}";
        }
      ];
    });
  };

  programs.helix = {
    enable = true;
    package = inputs.helix.packages.${pkgs.system}.helix;
    settings = {
      theme = "kanagawa";
      editor = {
        # faster autocompletions in 100ms, default is 400ms
        idle-timeout = 100;
        color-modes = true;
        true-color = true;
        statusline = {
          # this is the default
          # left = [ "mode" "spinner" "filename" "file-modification-indicator" ];
          right = [ "diagnostics" "selections" "position" "position-percentage" ];
          mode = {
            normal = "NORMAL";
            insert = "INSERT";
            select = "SELECT";
          };
        };
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        lsp.display-messages = true;
        soft-wrap.enable = true;
      };
      keys = {
        normal = {
          space = {
            F = "file_picker_in_current_buffer_directory";
            H = ":toggle lsp.display-inlay-hints";
            t = ":sh wezterm cli split-pane --bottom --percent 30 > /dev/null";
            v = ":sh wezterm cli split-pane --right --percent 80 gitui > /dev/null";
            e =
              # TODO: use current filepath as argument when https://github.com/helix-editor/helix/pull/6820 gets merged
              ":sh wezterm cli split-pane --bottom --percent 50 yazi > /dev/null";
          };
        };
      };
    };
    languages = {
      language-server = {
        rust-analyzer = {
          command = "rustup";
          args = [ "run" "nightly" "rust-analyzer" ];
          config = {
            check.command = "clippy";
          };
        };
        pyright = {
          command = "${pkgs.pyright}/bin/pyright-langserver";
          args = [ "--stdio" ];
          config = { };
        };
        ruff-lsp = {
          command = "${pkgs.ruff-lsp}/bin/ruff-lsp";
        };
      };
      language = [
        {
          name = "lua";
          indent = { tab-width = 4; unit = "    "; };
          auto-format = true;
          formatter = { command = "${pkgs.stylua}/bin/stylua"; args = [ "-" ]; };
        }
        {
          name = "toml";
          auto-format = true;
        }
        {
          name = "python";
          language-servers = [
            "pyright"
            "ruff-lsp"
          ];
          auto-format = true;
          formatter = {
            command = "${pkgs.ruff}/bin/ruff";
            args = [ "format" "-" ];
          };
        }
        {
          name = "bash";
          indent = { tab-width = 4; unit = "    "; };
          auto-format = true;
          formatter = {
            command = "${pkgs.shfmt}/bin/shfmt";
            args = [ "-i" "4" ];
          };
        }
        {
          name = "nix";
          auto-format = true;
          formatter = {
            command = "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt";
          };
        }

      ];
    };
  };

  programs.gitui = {
    enable = true;
    keyConfig = ''
      // bit for modifiers
      // bits: 0  None 
      // bits: 1  SHIFT
      // bits: 2  CONTROL
      //
      // Note:
      // If the default key layout is lower case,
      // and you want to use `Shift + q` to trigger the exit event,
      // the setting should like this `exit: Some(( code: Char('Q'), modifiers: ( bits: 1,),)),`
      // The Char should be upper case, and the shift modified bit should be set to 1.
      //
      // Note:
      // find `KeysList` type in src/keys/key_list.rs for all possible keys.
      // every key not overwritten via the config file will use the default specified there
      (
          open_help: Some(( code: F(1), modifiers: ( bits: 0,),)),

          move_left: Some(( code: Char('h'), modifiers: ( bits: 0,),)),
          move_right: Some(( code: Char('l'), modifiers: ( bits: 0,),)),
          move_up: Some(( code: Char('k'), modifiers: ( bits: 0,),)),
          move_down: Some(( code: Char('j'), modifiers: ( bits: 0,),)),
    
          popup_up: Some(( code: Char('p'), modifiers: ( bits: 2,),)),
          popup_down: Some(( code: Char('n'), modifiers: ( bits: 2,),)),
          page_up: Some(( code: Char('b'), modifiers: ( bits: 2,),)),
          page_down: Some(( code: Char('f'), modifiers: ( bits: 2,),)),
          home: Some(( code: Char('g'), modifiers: ( bits: 0,),)),
          end: Some(( code: Char('G'), modifiers: ( bits: 1,),)),
          shift_up: Some(( code: Char('K'), modifiers: ( bits: 1,),)),
          shift_down: Some(( code: Char('J'), modifiers: ( bits: 1,),)),

          edit_file: Some(( code: Char('I'), modifiers: ( bits: 1,),)),

          status_reset_item: Some(( code: Char('U'), modifiers: ( bits: 1,),)),

          diff_reset_lines: Some(( code: Char('u'), modifiers: ( bits: 0,),)),
          diff_stage_lines: Some(( code: Char('s'), modifiers: ( bits: 0,),)),

          stashing_save: Some(( code: Char('w'), modifiers: ( bits: 0,),)),
          stashing_toggle_index: Some(( code: Char('m'), modifiers: ( bits: 0,),)),

          stash_open: Some(( code: Char('l'), modifiers: ( bits: 0,),)),

          abort_merge: Some(( code: Char('M'), modifiers: ( bits: 1,),)),
      )    
    '';
  };
}
