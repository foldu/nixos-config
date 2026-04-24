{ inputs, pkgs, ... }:
{
  imports = [
    ./gtk.nix
    ./mpv.nix
    ./xdg-userdirs.nix
    ./xdg.nix
    ./ghostty.nix
    ./niri
    ./firefox.nix

    inputs.pickwp.homeManagerModules.pickwp
  ];

  home.packages = [
    inputs.eunzip.packages.${pkgs.stdenv.hostPlatform.system}.eunzip
    inputs.wpp-gtk.packages.${pkgs.stdenv.hostPlatform.system}.wpp
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
    feishin
    # temporarily needed until https://gitlab.gnome.org/GNOME/gnome-online-accounts/-/merge_requests/97
    thunderbird
    newsflash
    wl-clipboard
    unrar
    _7zz
    helium
  ]);

  services.pickwp.enable = true;
}
