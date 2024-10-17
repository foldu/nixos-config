{ pkgs, inputs, ... }:
{
  programs.yazi = {
    enable = false;
    package = inputs.yazi.packages.${pkgs.system}.yazi;
    settings = {
      opener = {
        image = [
          {
            exec = ''xdg-open "$@"'';
            desc = "Open";
          }
          {
            exec = ''gimp "$@"'';
            desc = "Edit";
          }
        ];
        archive = [
          {
            exec = ''unar "$1"'';
            desc = "Extract here";
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
            desc = "Play";
          }
        ];
        audio = [
          {
            exec = ''celluloid "$@"'';
            desc = "Play";
          }
        ];

        fallback = [
          {
            exec = ''xdg-open "$@"'';
            desc = "Open";
          }
        ];
      };
    };
  };
}
