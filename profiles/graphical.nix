{ pkgs, lib, config, inputs, configSettings, ... }:
let
  theme = configSettings.theme;
  systemConfig = config;
  hostName = config.networking.hostName;
in
{
  imports = [
    ./generic.nix
    ./graphical/bfq.nix
    ./graphical/desktop-portal.nix
    ./graphical/emacs.nix
    ./graphical/fancy-login.nix
    ./graphical/fonts.nix
    ./graphical/gnome-keyring.nix
    ./graphical/gnome.nix
    ./graphical/kde-connect.nix
    ./graphical/nfs.nix
    ./graphical/pipewire.nix
    ./graphical/qt5.nix
    ./graphical/syncthing.nix
    ../terminal-environment.nix
  ];

  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
    enableOnBoot = false;
  };

  documentation = {
    dev.enable = true;
    info.enable = false;
  };

  services.flatpak.enable = true;

  networking.firewall.enable = true;

  programs.dconf.enable = true;

  hardware.opengl.enable = true;

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_5_10;

  services.udev.extraRules = ''
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3748", \
    MODE:="0666", \
    SYMLINK+="stlinkv2_%n"
  '';

  home-manager.users.barnabas = { config, ... }: {
    imports = [
      ./graphical/celluloid.nix
      ./graphical/xdg-userdirs.nix
      ./graphical/xdg.nix
      ./graphical/gtk.nix
      ./graphical/mpd.nix
      inputs.pickwp.homeManagerModule
      inputs.wrrr.homeManagerModule
    ];

    home.file.".ssh/config".source = ../secrets/ssh-config;

    # TODO: sort this wall of crap
    home.packages = with pkgs; [
      eunzip
      ffmpeg
      youtube-dl
      pass
      pulsemixer
      zip
      dua
      imagemagick
      gnupg
      brave
      chromium
      tdesktop
      pwgen
      dfeet
      gimp
      streamlink
      wpp
      wl-clipboard
      manpages
      (
        pkgs.rust-bin.nightly.latest.rust.override {
          extensions = [
            "rust-src"
            "clippy"
            "rust-analyzer-preview"
          ];
          targets = [
            "x86_64-unknown-linux-musl"
            "aarch64-unknown-linux-gnu"
            "wasm32-unknown-unknown"
            "wasm32-wasi"
          ];
        }
      )
      cargo-deny
      cargo-outdated
      rnix-lsp
      cargo-edit
      cargo-flamegraph
      cargo-bloat
      tokei
      gdb
      openocd
      clang_11
      julia
      lld_11
      sqlite-interactive
      litecli
      pgcli
      binutils
      nodePackages.pyright
      cookiecutter
    ];

    services.pickwp.enable = true;

    services.wrrr.enable = true;

    programs.alacritty =
      let
        toFontSpec = type: {
          name = type;
          value = {
            family = configSettings.font.devMonospace.name;
            style = type;
          };
        };
        fontSpec = lib.listToAttrs (map toFontSpec [ "normal" "bold" "italic" ]);
      in
      {
        enable = true;
        package = pkgs.alacritty;
        settings = {
          env.TERM = "xterm-256color";
          cursor.unfocused_hollow = true;
          cursor.style = "Block";
          font = { size = 12.0; } // fontSpec;
          colors = {
            primary = {
              # hard contrast background - '#1d2021'
              background = "#282828";
              #background = "#32302f";
              #background = "#1d2021";
              # soft contrast background - "#32302f"
              foreground = "#fbf1c7";
              bright_foreground = "#f9f5d7";
              dim_foreground = "#f2e5bc";
            };
            cursor = {
              text = "CellBackground";
              cursor = "CellForeground";
            };
            vi_mode_cursor = {
              text = "CellBackground";
              cursor = "CellForeground";
            };
            selection = {
              text = "CellBackground";
              background = "CellForeground";
            };
            bright = {
              black = "#928374";
              red = "#fb4934";
              green = "#b8bb26";
              yellow = "#fabd2f";
              blue = "#83a598";
              magenta = "#d3869b";
              cyan = "#8ec07c";
              white = "#ebdbb2";
            };
            normal = {
              black = "#282828";
              red = "#cc241d";
              green = "#98971a";
              yellow = "#d79921";
              blue = "#458588";
              magenta = "#b16286";
              cyan = "#689d6a";
              white = "#a89984";
            };
            dim = {
              black = "#32302f";
              red = "#9d0006";
              green = "#79740e";
              yellow = "#b57614";
              blue = "#076678";
              magenta = "#8f3f71";
              cyan = "#427b58";
              white = "#928374";
            };
          };
        };
      };

    programs.firefox = {
      enable = true;
      profiles =
        let
          genericProfile = {
            userChrome = lib.readFile ../config/firefox/userChrome.css;
            settings = import ../config/firefox/userjs.nix;
          };
        in
        {
          "normal" = genericProfile // {
            id = 0;
            isDefault = true;
          };
          "backup" = genericProfile // { id = 1; };
        };
    };
  };
}
