{ inputs, pkgs, ... }:
{
  imports = [
    ./gtk.nix
    ./kitty
    ./librewolf.nix
    ./mpv.nix
    ./xdg-userdirs.nix
    ./xdg.nix
    ./yazi.nix

    inputs.pickwp.homeManagerModule
    inputs.atchr.homeManagerModule
  ];

  home.packages =
    [
      inputs.random-scripts.packages.${pkgs.system}.foldu-random-scripts
      inputs.nix-stuff.packages.${pkgs.system}.eunzip
      inputs.wpp-gtk.packages.${pkgs.system}.wpp
    ]
    ++ (with pkgs; [
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
      element-desktop
      # temporarily needed until https://gitlab.gnome.org/GNOME/gnome-online-accounts/-/merge_requests/97
      thunderbird
      newsflash
      wl-clipboard
      unrar
      _7zz
    ]);

  services.pickwp.enable = true;

  services.wrrr.enable = true;
}
