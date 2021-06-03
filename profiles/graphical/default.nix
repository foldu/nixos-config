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
      rnix-lsp
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
        "ctrl+v" = "paste_from_clipboard";
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

    programs.firefox = {
      enable = true;
      profiles =
        let
          genericProfile = {
            userChrome = lib.readFile ../../config/firefox/userChrome.css;
            settings = {
              # turn off all(hopefully) telemetry
              "toolkit.telemetry.enabled" = false;
              "browser.newtabpage.activity-stream.telemetry.structuredIngestion.endpoint" = "";
              "toolkit.telemetry.server" = "";
              "toolkit.telemetry.shutdownPingSender.enabled" = false;
              "toolkit.telemetry.updatePing.enabled" = false;
              "datareporting.healthreport.uploadEnabled" = false;
              "datareporting.healthreport.service.enabled" = false;
              "toolkit.coverage.enabled" = false;

              # do not load random things I didn't even click on
              "network.dns.disablePrefetch" = true;
              "network.predictor.enable-prefetch" = false;
              "network.prefetch-next" = false;

              # pocket will never be succesfull just stop
              "extensions.pocket.enabled" = false;

              # disable useless(for me) apis that could be used for fingerprinting
              "dom.battery.enabled" = false;
              "dom.enable_performance" = false;
              "dom.enable_resource_timing" = false;
              "dom.webaudio.enabled" = false;
              "webgl.disabled" = true;

              # absolutely nobody cares about dnt
              "privacy.donottrackheader.enabled" = false;

              # enable userChrome.css
              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

              # no
              "app.normandy.enabled" = false;
            };
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
