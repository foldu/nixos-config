{ config, lib, pkgs, ... }: {
  services.xserver.desktopManager = {
    gnome.enable = true;
    xterm.enable = lib.mkForce false;
  };

  environment.gnome.excludePackages = with pkgs.gnome; [
    cheese
    gedit
    pkgs.gnome-photos
    gnome-logs
    gnome-contacts
    epiphany
    gnome-music
    file-roller
    gnome-software
  ];

  # conflicts with tlp
  services.power-profiles-daemon.enable = false;

  environment.systemPackages = with pkgs.gnomeExtensions; [
    appindicator
    blur-my-shell
    gnome-ui-tune
    just-perfection
    pop-os-shell
    volume-mixer
  ];

  # disable laptop melting service
  services.gnome.tracker-miners.enable = false;

  # gunome _still_ has no server side decorations and alacritty windows look weird
  # because of that
  environment.sessionVariables.WINIT_UNIX_BACKEND = "x11";

  services.gnome = {
    #gnome-online-miners.enable = lib.mkForce false;
    #gnome-user-share.enable = false;
    gnome-initial-setup.enable = false;
    gnome-remote-desktop.enable = false;
  };

  home-manager.users.barnabas = { lib, config, ... }: {
    home.packages = with pkgs; [
      gnome.gnome-tweaks
      gnome.dconf-editor
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

      "org/gnome/desktop/input-sources" =
        let
          mkTuple = lib.hm.gvariant.mkTuple;
        in
        {
          sources = [ (mkTuple [ "xkb" "us" ]) (mkTuple [ "xkb" "us+intl" ]) ];
          xkb-options = [ "caps:escape" ];
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
        name = "Yaru";
      };

      "org/gnome/desktop/wm/keybindings" = {
        # remove unused bindings so they don't conflict
        switch-to-workspace-up = "@as []";
        switch-to-workspace-down = "@as []";
        move-to-workspace-up = "@as []";
        move-to-workspace-down = "@as []";

        close = [ "<Super>q" ];
        minimize = [ ];
        move-to-monitor-left = "@as []";
        move-to-monitor-right = "@as []";
        move-to-workspace-left = [ "<Shift><Super>j" ];
        move-to-workspace-right = [ "<Shift><Super>k" ];
        switch-to-workspace-left = [ "<Primary><Super>j" ];
        switch-to-workspace-right = [ "<Primary><Super>k" ];
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
        command = "kitty --single-instance";
        name = "Open terminal";
      };

      "org/gnome/shell" = {
        favorite-apps = [
          "brave-browser.desktop"
          "telegramdesktop.desktop"
          "kitty.desktop"
          "emacs.desktop"
        ];
        enabled-extensions = [
          "appindicatorsupport@rgcjonas.gmail.com"
          "blur-my-shell@aunetx"
          "drive-menu@gnome-shell-extensions.gcampax.github.com"
          "gnome-ui-tune@itstime.tech"
          "just-perfection-desktop@just-perfection"
          "pop-shell@system76.com"
          "user-theme@gnome-shell-extensions.gcampax.github.com"
        ];
        disable-extension-version-validation = true;
      };

      "org/gnome/shell/extensions/just-perfection" = {
        animation = 4;
        background-menu = true;
        clock-menu-position = 0;
        clock-menu-position-offset = 0;
        dash = false;
        hot-corner = true;
        osd = true;
        panel = true;
        panel-arrow = true;
        search = false;
        theme = false;
        top-panel-position = 0;
        workspace = true;
        workspace-switcher-size = 15;
      };

      "org/gnome/shell/extensions/blur-my-shell" = {
        blur-dash = false;
        blur-lockscreen = true;
        blur-overview = true;
        blur-panel = false;
        brightness = 0.6;
        dash-opacity = 0.12;
        hacks-level = 1;
        sigma = 30;
        static-blur = true;
      };

      "org/gnome/shell/extensions/gnome-ui-tune" = {
        hide-search = false;
        increase-thumbnails-size = false;
      };

      "org/gnome/shell/extensions/pop-shell" = {
        hint-color-rgba = "rgba(223, 74, 22, 1)";
        active-hint = true;
        show-title = true;
        smart-gaps = true;
        tile-by-default = true;
      };

      "org/gnome/shell/extensions/shell-volume-mixer" = {
        always-show-input-streams = true;
        position = "aggregateMenu";
        remove-original = false;
        show-detailed-sliders = false;
        show-percentage-label = false;
        show-system-sounds = true;
        show-virtual-streams = true;
        use-symbolic-icons = true;
      };

      "org/gnome/desktop/peripherals/touchpad" = {
        natural-scroll = false;
        tap-to-click = true;
        two-finger-scrolling-enabled = true;

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
        center-new-windows = true;
        dynamic-workspaces = true;
        workspaces-only-on-primary = true;
      };
    };
  };
}
