{ pkgs, ... }: {
  programs.yazi = {
    enable = true;
    settings = {
      opener = {
        image = [
          {
            exec = ''xdg-open "$@"'';
            display_name = "Open";
          }
          {
            exec = ''gimp "$@"'';
            display_name = "Edit";
          }
        ];
        archive = [
          {
            exec = ''unar "$1"'';
            display_name = "Extract here";
          }
        ];
        text = [
          {
            exec =
              let
                script = pkgs.writeScript "thing" ''
                  #!${pkgs.nushell}/bin/nu
                  def main [...args: string] {
                    let up_id = (wezterm cli get-pane-direction up)
                    if ($up_id == "") {
                      hx $args
                    } else {
                      $":open ($args | first)\r\n" | wezterm cli send-text --pane-id $up_id --no-paste 
                      ^wezterm cli activate-pane-direction up 
                    }
                  }
                '';
              in
              ''${script} "$@"'';

            block = true;
          }
        ];
        video = [
          {
            exec = ''celluloid "$@"'';
            display_name = "Play";
          }
        ];
        audio = [
          {
            exec = ''celluloid "$@"'';
            display_name = "Play";
          }
        ];

        fallback = [
          {
            exec = ''xdg-open "$@"'';
            display_name = "Open";
          }
        ];
      };
    };
  };
}
