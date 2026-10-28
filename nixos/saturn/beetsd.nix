{
  config,
  inputs,
  ...
}:
let
  port = 8000;
  domain = "beetsd.home.5kw.li";

  musicDir = "/srv/media/blub/data/music";
  libraryDb = "/srv/media/blub/data/beets/library.db";
  stagingDir = "/srv/media/fast/staging";
  youtubeDir = "/srv/media/blub/data/youtube";

  # services.beetsd.watchDirs would make the module create it with mode 0750
  # barnabas:users and lock transmission out of its own download directory.
  # Transmission owns the torrent tree (see ./transmission), so pass the same
  # value through the environment instead; beetsd reads it as a member of the
  # transmission group.
  watchDir = "/srv/media/fast/torrents/complete/music";

  # The module hardcodes 0750 on services.beetsd.musicDir. Jellyfin and
  # Navidrome run with PrivateUsers, so they read the media tree through its
  # world bits, not through a group. That is why the music tree is 0755 today,
  # and why the module gets a private placeholder instead of the real path;
  # beetsd is given the real directory through the environment and
  # ReadWritePaths below.
  managedMusicDir = "/var/lib/beetsd/music";
in
{
  imports = [ inputs.beetsd.nixosModules.default ];

  services.beetsd = {
    enable = true;

    # The existing library and the Samba share are barnabas:users, and the
    # import should keep writing as that identity rather than leave a tree of
    # beetsd-owned files behind.
    user = "barnabas";
    group = "users";
    createUser = false;

    musicDir = managedMusicDir;
    inherit libraryDb stagingDir;

    watchDirs = [ ];
    extraEnvironment = {
      BEETSD_MUSIC_DIR = musicDir;
      BEETSD_WATCH_DIRS = builtins.toJSON [ watchDir ];
      # ProtectHome keeps the service out of barnabas' home, so Deno's default
      # cache there is not writable.
      DENO_DIR = "/var/lib/beetsd/deno";
    };

    youtubeEnabled = true;
    youtubeVideoDir = youtubeDir;

    # Suggestions only prefill the review form; the operator still imports.
    # The key is a sops secret, never a Nix string.
    aiBaseUrl = "https://api.deepseek.com";
    aiModel = "deepseek-flash";
    aiApiKeyFile = config.sops.secrets."deepseek/api-key".path;

    inherit port;
  };

  sops.secrets."deepseek/api-key" = {
    owner = "barnabas";
    mode = "0400";
    restartUnits = [ "beetsd.service" ];
  };

  # The real music directory is outside the module's writable set, so add it.
  systemd.services.beetsd.serviceConfig.ReadWritePaths = [ musicDir ];

  # Be explicit about the one supplementary group the watcher needs: the
  # torrent tree is transmission:transmission, and the primary group is users.
  systemd.services.beetsd.serviceConfig.SupplementaryGroups = [ "transmission" ];

  # 0022 keeps imported audio and the YouTube videos world-readable for the
  # Jellyfin and Navidrome processes that read them; the package's default is
  # the same, but say so here because those readers depend on it.
  systemd.services.beetsd.serviceConfig.UMask = "0022";

  # beetsd creates the artist/album directories under youtubeDir itself. 2755
  # keeps the same world-readable model as the music tree (Jellyfin's
  # PrivateUsers sees the owner as nobody), while the setgid bit keeps new
  # directories in the users group for Samba and for future group-based readers.
  systemd.tmpfiles.rules = [
    "d ${youtubeDir} 2755 barnabas users -"
    "d /var/lib/beetsd/deno 0700 barnabas users -"
  ];

  services.caddy.virtualHosts.${domain}.extraConfig = ''
    forward_auth https://auth.home.5kw.li {
      uri /api/authz/forward-auth
      copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
      header_up Host {upstream_hostport}
    }
    reverse_proxy 127.0.0.1:${toString port}
  '';
}
