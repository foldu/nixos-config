{ pkgs, lib, config, inputs, configSettings, ... }:
let
  theme = configSettings.theme;
  systemConfig = config;
  hostName = config.networking.hostName;
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

  # FIXME: temporary fix until I figure out why some gtk applications
  # ignore both settings.ini and the thing in dconf
  environment.sessionVariables.GTK_THEME = "Yaru-dark";

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
      ./gtk.nix
      ./rust.nix
      ./xdg-userdirs.nix
      ./xdg.nix
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
      tdesktop
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
      clang_11
      clang-tools
      lld_11
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
        "ctrl+c" = "copy_or_interrupt";
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
