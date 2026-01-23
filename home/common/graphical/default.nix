{ inputs, pkgs, ... }:
{
  imports = [
    ./gtk.nix
    ./kitty
    ./mpv.nix
    ./xdg-userdirs.nix
    ./xdg.nix
    ./yazi.nix
    ./ghostty.nix
    ./niri
    ./firefox
    ./obsidian.nix

    inputs.pickwp.homeManagerModules.pickwp
  ];

  home.packages = [
    inputs.nix-stuff.packages.${pkgs.system}.eunzip
    inputs.wpp-gtk.packages.${pkgs.system}.wpp
  ]
  ++ (with pkgs; [
    mumble
    # opencloud-desktop
    steam-run
    kooha
    croc
    ffmpeg
    yt-dlp
    pass
    imagemagick
    gnupg
    brave
    chromium
    pwgen
    d-spy
    gimp
    streamlink
    supersonic
    # temporarily needed until https://gitlab.gnome.org/GNOME/gnome-online-accounts/-/merge_requests/97
    thunderbird
    newsflash
    wl-clipboard
    unrar
    _7zz
  ]);

  services.pickwp.enable = true;
}
