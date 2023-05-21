{ inputs, pkgs, ... }: {
  imports = [
    ./gtk.nix
    ./kitty
    ./mpv.nix
    ./xdg-userdirs.nix
    ./xdg.nix

    inputs.pickwp.homeManagerModule
    inputs.atchr.homeManagerModule
  ];

  home.packages = with pkgs; [
    steam-run
    kooha
    inputs.nix-stuff.packages.${pkgs.system}.eunzip
    croc
    inputs.random-scripts.packages.${pkgs.system}.foldu-random-scripts
    ffmpeg
    yt-dlp
    pass
    imagemagick
    # uses node 16
    # bitwarden
    gnupg
    brave
    chromium
    pwgen
    dfeet
    gimp
    tdesktop
    streamlink
    inputs.wpp-gtk.packages.${pkgs.system}.wpp
    element-desktop
    # temporarily needed until https://gitlab.gnome.org/GNOME/gnome-online-accounts/-/merge_requests/97
    thunderbird
    newsflash
    wl-clipboard
  ];

  services.pickwp.enable = true;

  services.wrrr.enable = true;
}
