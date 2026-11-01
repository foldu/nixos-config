{
  config,
  inputs,
  lib,
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

  # Flatpak mounts the host font dirs into the sandbox as read-only store paths,
  # whose files and directories are all mtime 1970. Fontconfig only rescans a
  # directory when it looks newer than the cache entry for it, so that cache never
  # goes stale on its own and fonts added by a later generation stay invisible to
  # flatpak apps -- CJK text renders as tofu until the cache is dropped by hand.
  # Clear it whenever the merged font dir changes, so `nixos-rebuild switch` is
  # enough to make new fonts show up.
  home.activation.refreshFlatpakFontCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    fontDir=$(readlink -f /run/current-system/sw/share/X11/fonts)
    stamp="$HOME/.cache/flatpak-fonts.stamp"
    if [ "$(cat "$stamp" 2>/dev/null)" != "$fontDir" ]; then
      for cache in "$HOME"/.var/app/*/cache/fontconfig; do
        if [ -e "$cache" ]; then
          run rm -rf "$cache"
        fi
      done
      run mkdir -p "$(dirname "$stamp")"
      printf '%s\n' "$fontDir" > "$stamp"
    fi
  '';

  services.pickwp.enable = true;
}
