{
  config,
  lib,
  pkgs,
  ...
}:
let
  # `dsh web` mints a fresh authentication token per process and prints the URL
  # carrying it once, at startup. The service parks that URL in its runtime
  # directory and the Electron window reads it back, so windows attach without
  # scraping the journal (which still receives everything the server prints).
  #
  # 3090, not the 3080 the web profile defaults to: an always-on service that
  # lost a bind fight with a hand-started `dsh web` would only restart-loop.
  port = 3090;

  publishUrl = pkgs.writeShellScript "dsh-web" ''
    set -eu
    umask 077

    url_file="''${RUNTIME_DIRECTORY:?RUNTIME_DIRECTORY is unset}/url"
    rm -f "$url_file"

    # The URL line is the server's readiness signal, so publish it the moment
    # it arrives rather than buffering the server's output.
    "${pkgs.dsh}/bin/dsh" web --no-open --port ${toString port} |
      while IFS= read -r line || [ -n "$line" ]; do
        printf '%s\n' "$line"
        case "$line" in
          "dsh web: http"*) printf '%s\n' "''${line#dsh web: }" > "$url_file" ;;
        esac
      done
  '';
in
{
  home.packages = [ pkgs.dsh-desktop ];

  systemd.user.services.dsh-web = {
    Unit = {
      Description = "DeepSeek Harness web GUI server";
    };

    Service = {
      ExecStart = publishUrl;
      Restart = "always";
      RestartSec = 5;

      # systemd creates this 0700 directory with the unit and removes it with
      # the unit, so a restart can never leave the window holding a dead token.
      # dsh-desktop looks for $XDG_RUNTIME_DIR/dsh-web/url, which this is.
      RuntimeDirectory = "dsh-web";
      RuntimeDirectoryMode = "0700";

      # The agent shells out to the same tools a login session finds; a user
      # service inherits none of them.
      Environment = "PATH=${
        lib.makeBinPath [ config.home.profileDirectory ]
      }:/run/current-system/sw/bin:/run/wrappers/bin";
    };

    Install.WantedBy = [ "default.target" ];
  };
}
