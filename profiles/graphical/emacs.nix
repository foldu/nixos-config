{ pkgs, inputs, lib, ... }:
let
  doomRev = inputs.doom-emacs.rev;
in
{
  home-manager.users.barnabas = { config, ... }: {
    # zomfg emacs can adhere to XDG now
    xdg.configFile."doom" = {
      source = ../../config/doom;
      recursive = true;
      # FIXME: do this properly
      onChange = ''
        #!/bin/sh
        set -e
        emacs="$HOME/.config/emacs"
        doom="$emacs/bin/doom"

        if ! [ -d "$emacs" ]; then
          ${pkgs.git}/bin/git clone https://github.com/hlissner/doom-emacs.git "$emacs"
          "$doom" -y install
        fi

        cd "$emacs"
        current_rev=$(git rev-parse HEAD)
        if ! [ "$current_rev" = "${doomRev}" ]; then
          # I swear not to touch this directory
          git reset --hard
          git checkout develop
          git pull
          git checkout "${doomRev}"
        fi

        "$doom" sync
      '';
    };

    programs.emacs = {
      enable = true;
      package = pkgs.emacsPgtkGcc;
      extraPackages = epkgs: [
        epkgs.vterm
      ];
    };

    home.packages = with pkgs; [
      nixpkgs-fmt
      texlive.combined.scheme-full
      gnumake
      texlab
      nodePackages.typescript-language-server
      nodePackages.typescript
      nodePackages.prettier
      pandoc
      plantuml
      libnotify
      # for lemminx
      jre
    ];
  };
}
