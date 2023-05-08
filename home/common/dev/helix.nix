{pkgs, ...}: {
  programs.helix = {
    enable = true;
    settings = {
      theme = "kanagawa";
      keys = {
        normal = {
          space = {
            F = "file_picker_in_current_buffer_directory";
          };
        };
      };
    };
    languages = [
      {
        name = "nix";
        auto-format = true;
        formatter = {
          command = "${pkgs.alejandra}/bin/alejandra";
          args = ["-q"];
        };
      }
    ];
  };
}
