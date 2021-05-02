{ config, lib, pkgs, ... }: {
  services.xserver.desktopManager = {
    gnome3.enable = true;
    xterm.enable = lib.mkForce false;
  };

  environment.gnome3.excludePackages = with pkgs.gnome3; [
    cheese
    gedit
    gnome-photos
    gnome-logs
    gnome-contacts
    epiphany
    gnome-music
    file-roller
  ];

  environment.systemPackages = with pkgs.gnomeExtensions; [
    appindicator
    pkgs.myGnomeExtensions.pop-os-shell
  ];

  # gunome _still_ has no server side decorations and alacritty windows look weird
  # because of that
  environment.sessionVariables.WINIT_UNIX_BACKEND = "x11";

  # remove gnome software
  services.flatpak.guiPackages = lib.mkForce [ ];

  services.gnome3 = {
    gnome-online-miners.enable = lib.mkForce false;
    gnome-user-share.enable = false;
    gnome-initial-setup.enable = false;
    gnome-remote-desktop.enable = false;
  };

  home-manager.users.barnabas = { config, ... }: {
    home.packages = with pkgs; [
      gnome3.gnome-tweak-tool
      gnome3.dconf-editor
      dconf2nix
    ];

    dconf.enable = true;
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        document-font-name = "Roboto Slab 11";
        #font-name = "Fira Sans Semi-Light 10";
        monospace-font-name = "Fira Mono 11";

        show-battery-percentage = true;

        clock-show-seconds = true;
      };

      "org/gnome/desktop/wm/preferences" = {
        titlebar-font = "Inter Semi Bold 10";
      };

      "org/gnome/desktop/privacy" = {
        send-software-usage-stats = false;
        report-technical-problems = false;
      };

      "org/gnome/desktop/peripherals/keyboard" = {
        delay = 200;
        repeat-interval = 25;
      };

      "org/gnome/desktop/input-sources" = {
        xkb-options = [ "caps:escape" "compose:ralt" ];
      };

      "org/gnome/settings-daemon/plugins/color" = {
        active = true;
        night-light-enabled = true;
        night-light-schedule-automatic = true;
        night-light-temperature = 2800;
      };

      "org/gnome/system/location" = {
        enabled = true;
      };

      "org/gnome/settings-daemon/plugins/power" = {
        power-button-action = "interactive";
        sleep-inactive-ac-type = "nothing";
        sleep-inactive-battery-type = "nothing";
      };

      "org/gnome/gnome-session" = {
        auto-save-session = true;
      };

      "system/locale" = {
        region = "de_DE.UTF-8";
      };

      "org/gnome/desktop/datetime" = {
        automatic-timezone = true;
      };

      "org/gnome/shell/extensions/user-theme" = {
        name = "pop-dark";
      };

      "org/gnome/desktop/wm/keybindings" = {
        close = [ "<Super>q" ];
        minimize = [ ];
        move-to-monitor-left = "@as []";
        move-to-monitor-right = "@as []";
        move-to-workspace-down = "@as []";
        move-to-workspace-up = "@as []";
        switch-to-workspace-down = [ "<Primary><Super>j" ];
        switch-to-workspace-up = [ "<Primary><Super>k" ];
      };

      "org/gnome/shell/keybindings" = {
        toggle-overview = "@as []";
      };

      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [ "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/" ];
        email = [ "<Super>e" ];
        home = [ "<Super>f" ];
        rotate-video-lock-static = "@as []";
        screensaver = [ "<Super>Escape" ];
        www = [ "<Super>b" ];
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        binding = "<Super>t";
        command = "alacritty";
        name = "Open terminal";
      };

      "org/gnome/shell" = {
        favorite-apps = [
          "brave-browser.desktop"
          "telegramdesktop.desktop"
          "Alacritty.desktop"
          "emacs.desktop"
        ];
        enabled-extensions = [
          "drive-menu@gnome-shell-extensions.gcampax.github.com"
          "appindicatorsupport@rgcjonas.gmail.com"
          "user-theme@gnome-shell-extensions.gcampax.github.com"
          "pop-shell@system76.com"
        ];
      };


      "org/gnome/eog/plugins" = {
        active-plugins = [ "fullscreen" ];
      };

      "org/gnome/eog/ui" = {
        image-gallery = false;
        sidebar = false;
        statusbar = true;
      };

      "org/gnome/mutter" = {
        "center-new-windows" = true;
      };
    };
  };
}
