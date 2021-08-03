{ pkgs, lib, config, inputs, configSettings, ... }:
let
  theme = configSettings.theme;
  systemConfig = config;
  hostName = config.networking.hostName;

  lol = pkgs.stdenv.mkDerivation {
    pname = "ble-ws-central-dbus";
    src = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE busconfig PUBLIC
      "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
      "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
      <busconfig>
        <policy user="barnabas">
          <allow own="li._5kw.BleWsCentral"/>
        </policy>
        <policy context="default">
          <allow send_destination="li._5kw.BleWsCentral"/>
          <allow receive_sender="li._5kw.BleWsCentral"/>
        </policy>
      </busconfig>
    '';
    dontUnpack = true;
    version = "0.1";
    installPhase = ''
      mkdir -p "$out/share/dbus-1/system.d"
      echo "$src" > "$out/share/dbus-1/system.d/li._5kw.BleWsCentral.conf"
    '';
  };
in
{
  imports = [
    ../generic.nix
    ./bfq.nix
    ./desktop-portal.nix
    ./emacs.nix
    ./fancy-login.nix
    ./fonts.nix
    ./gnome.nix
    ./nfs.nix
    ./pipewire.nix
    ./qt5.nix
    ./syncthing.nix
    ../../terminal-environment.nix
  ];

  environment.sessionVariables = {
    # FIXME: temporary fix until I figure out why some gtk applications
    # ignore both settings.ini and the thing in dconf
    GTK_THEME = "Yaru-dark";

    # FIXME: incremental compilation is kind of broken on stable so this needs
    # to be set to reenable it
    # I'd rather have broken incremental builds than none at all
    RUSTC_FORCE_INCREMENTAL = "1";
  };

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

  environment.systemPackages = [ lol ];

  services.flatpak.enable = true;

  networking.firewall.enable = true;

  programs.dconf.enable = true;

  hardware.opengl.enable = true;

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_5_13;

  services.udev.extraRules = ''
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3748", \
    MODE:="0666", \
    SYMLINK+="stlinkv2_%n"
  '';

  home-manager.users.barnabas = { config, ... }: {
    imports = [
      ./gtk.nix
      ./rust.nix
      ./xdg-userdirs.nix
      ./xdg.nix
      ./beets.nix
      ./firefox.nix
      inputs.pickwp.homeManagerModule
      inputs.wrrr.homeManagerModule
    ];

    home.file.".ssh/config".source = ../../secrets/ssh-config;

    # TODO: sort this wall of crap
    home.packages = with pkgs; [
      (
        python39.withPackages (
          p: with p; [
            sh
            requests
            ipython
            black
          ]
        )
      )
      neovide
      gnome-podcasts
      eunzip
      croc
      ffmpeg
      youtube-dl
      freetube
      pass
      pulsemixer
      zip
      dua
      imagemagick
      gnupg
      brave
      chromium
      #tdesktop
      pwgen
      dfeet
      gimp
      pickwp-gtk
      mpv
      streamlink
      wpp
      wl-clipboard
      manpages
      tokei
      gdb
      openocd
      ccls
      clang-tools
      clang_12
      # gcc
      lld_12
      sqlite-interactive
      litecli
      #pgcli
      binutils
      nodePackages.pyright
      cookiecutter
      lollypop
    ];

    services.pickwp.enable = true;

    services.wrrr.enable = true;

    programs.kitty = {
      enable = true;
      font = {
        name = configSettings.font.devMonospace.name;
        size = 12;
      };
      keybindings = {
        #"ctrl+c" = "copy_or_interrupt";
        #"ctrl+v" = "paste_from_clipboard";
        "ctrl+shift+j" = "previous_tab";
        "ctrl+shift+k" = "next_tab";
      };
      settings = {
        tab_bar_style = "powerline";
        enable_audio_bell = "no";
        disable_ligatures = "always";
        update_check_interval = 0;
        linux_display_server = "x11";
      };
    };
  };
}
