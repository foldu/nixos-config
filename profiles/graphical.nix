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
              background = "0x2E3440";
              foreground = "0xD8DEE9";
            };

            # Normal colors
            normal = {
              black = "0x3B4252";
              red = "0xBF616A";
              green = "0xA3BE8C";
              yellow = "0xEBCB8B";
              blue = "0x81A1C1";
              magenta = "0xB48EAD";
              cyan = "0x88C0D0";
              white = "0xE5E9F0";
            };

            # Bright colors
            bright = {
              black = "0x4C566A";
              red = "0xBF616A";
              green = "0xA3BE8C";
              yellow = "0xEBCB8B";
              blue = "0x81A1C1";
              magenta = "0xB48EAD";
              cyan = "0x8FBCBB";
              white = "0xECEFF4";
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
