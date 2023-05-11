{ pkgs, ... }: {
  programs.helix = {
    enable = true;
    settings = {
      theme = "kanagawa";
      editor = {
        # faster autocompletions in 100ms, default is 400ms
        idle-timeout = 100;
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
          };
        };
      };
    };
    languages = [
      {
        name = "nix";
        auto-format = true;
        formatter = {
          command = "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt";
        };
      }
      {
        name = "rust";
        language-server = {
          command = "rustup";
          args = [ "run" "nightly" "rust-analyzer" ];
        };
      }
    ];
  };

  programs.lazygit = {
    enable = true;
    settings.gui = {
      showBottomBar = false;
      showIcons = true;
    };
  };
}
