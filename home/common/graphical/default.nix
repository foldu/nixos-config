{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    ./gtk.nix
    ./mpv.nix
    ./xdg-userdirs.nix
    ./xdg.nix
    ./ghostty.nix
    ./dsh.nix
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
    # currently broken
    # croc
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
    photocraft
    cadcraft
    filmcraft
    vectorcraft
    # streamlink
    feishin
    # temporarily needed until https://gitlab.gnome.org/GNOME/gnome-online-accounts/-/merge_requests/97
    thunderbird
    newsflash
    wl-clipboard
    unrar
    _7zz
    helium
  ]);

  # Bitwarden's built-in SSH agent is the session agent here. This lands in
  # ~/.config/environment.d, which only the systemd user manager reads: niri.service
  # and dms inherit from it and hand it to everything they launch, while sshd
  # logins never consult the user manager and keep whatever (forwarded) socket
  # sshd set.
  systemd.user.sessionVariables.SSH_AUTH_SOCK = "${config.home.homeDirectory}/.bitwarden-ssh-agent.sock";

  services.pickwp.enable = true;
}
