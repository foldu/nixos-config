{ pkgs
, lib
, ...
}: {
  home.packages = with pkgs; [
    gnome.gnome-tweaks
    gnome.dconf-editor
    dconf2nix
    (pkgs.writeShellApplication {
      name = "xhide";
      runtimeInputs = with pkgs; [ kitty xdotool ];
      text = builtins.readFile ./xhide.sh;
    })
  ];

  dconf.enable = true;
  dconf.settings =
    let
      customKeybinds = [
        {
          binding = "<Shift><Super>Return";
          command = "wezterm";
          name = "Open terminal";
        }
        # {
        #   binding = "<Super>e";
        #   command =
        #     let
        #       script = pkgs.writeText "floating-term" ''
        #         #!/bin/sh
        #         session=$(
        #             cat <<EOF
        #         cd ~/nixos-config/
        #         launch nu
        #         new_tab
        #         cd ~/
        #         launch nu
        #         EOF
        #         )

        #         echo "$session" | kitty --class "Floating Term" --session -
        #       '';
        #     in
        #     "xhide --cmd \"sh ${script}\" --name floating-term --windowclass \"Floating Term\"";
        #   name = "Open floating terminal";
        # }
      ];
      keybindRange = lib.lists.range 0 (lib.lists.length customKeybinds);
      dconfKeybinds =
        builtins.listToAttrs
          (lib.flip map (lib.lists.zipLists keybindRange customKeybinds) ({ fst
                                                                          , snd
                                                                          ,
                                                                          }: {
            name = "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${toString fst}";
            value = snd;
          }));
      # NOTE: yes they're different, note the prefixed and suffixed "/"
      dconfKeybindPaths = lib.flip map keybindRange (n: "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${toString n}/");
    in
    {
      "org/gnome/desktop/interface" = {
        document-font-name = "Roboto Slab 11";
        color-scheme = "prefer-dark";
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

      "org/gnome/desktop/wm/keybindings" = {
        close = [ "<Super>q" ];
        minimize = [ ];
        # maximize = "<Super>m";

        # move-to-monitor-left = "<Super><Shift>h";
        # move-to-monitor-right = "<Super><Shift>l";
        # switch-to-monitor-left = "<Super>h";
        # switch-to-monitor-right = "<Super>l";

        move-to-workspace-left = [ "<Super><Shift>bracketleft" ];
        move-to-workspace-right = [ "<Super><Shift>bracketright" ];
        switch-to-workspace-left = [ "<Super>bracketleft" ];
        switch-to-workspace-right = [ "<Super>bracketright" ];
      };

      "org/gnome/shell/keybindings" = {
        toggle-overview = "@as []";
      };

      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = dconfKeybindPaths;
        # email = [ "<Super>e" ];
        # home = [ "<Super>f" ];
        # rotate-video-lock-static = "@as []";
        # screensaver = [ "<Super>Escape" ];
        # www = [ "<Super>b" ];
      };

      "org/gnome/shell" = {
        favorite-apps = [
          "brave-browser.desktop"
          "telegramdesktop.desktop"
          "kitty.desktop"
        ];
        enabled-extensions = [
          "appindicatorsupport@rgcjonas.gmail.com"
          "drive-menu@gnome-shell-extensions.gcampax.github.com"
          "vertical-workspaces@G-dH.github.com"
          "paperwm@hedning:matrix.org"
        ];
        disable-extension-version-validation = true;
      };

      "org/gnome/shell/extensions/vertical-workspaces" = {
        dash-position = 2;
        layout-module = true;
        overview-mode = 0;
        panel-position = 0;
        profile-name-1 = "GNOME 3";
        profile-name-2 = "GNOME 40+ - Bottom Hot Edge";
        profile-name-3 = "Hot Corner Centric - Top Left Hot Corner";
        profile-name-4 = "Dock Overview - Bottom Hot Edge";
        search-fuzzy = false;
        show-ws-preview-bg = false;
        show-wst-labels-on-hover = false;
        startup-state = 0;
        ws-thumbnails-position = 5;
      };

      # "org/gnome/shell/extensions/forge" = {
      #   window-gap-hidden-on-single = true;
      # };

      "org/gnome/shell/extensions/paperwm" = {
        horizontal-margin = 5;
        override-hot-corner = false;
        use-default-background = true;
        vertical-margin = 5;
        vertical-margin-bottom = 5;
        window-gap = 5;
      };

      "org/gnome/shell/extensions/paperwm/keybindings" = {
        # move-down = [ "<Control><Super>Down" "<Control><Super>j" ];
        # move-up = [ "<Control><Super>Up" "<Control><Super>k" ];
        # switch-down = [ "<Super>Down" "<Super>j" ];
        # switch-left = [ "<Super>Left" "<Super>h" ];
        # switch-right = [ "<Super>Right" "<Super>l" ];
        # switch-up = [ "<Super>Up" "<Super>k" ];
      };


      # "org/gnome/shell/extensions/just-perfection" = {
      #   animation = 4;
      #   background-menu = true;
      #   clock-menu-position = 0;
      #   clock-menu-position-offset = 0;
      #   dash = false;
      #   hot-corner = true;
      #   osd = true;
      #   panel = true;
      #   panel-arrow = true;
      #   search = false;
      #   theme = false;
      #   top-panel-position = 0;
      #   workspace = true;
      #   workspace-switcher-should-show = true;
      #   workspace-switcher-size = 15;
      # };

      "org/gnome/shell/app-switcher" = {
        current-workspace-only = true;
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

      "org/gnome/nautilus/preferences" = {
        show-delete-permanently = true;
      };

      # "org/gnome/mutter" = {
      #   center-new-windows = true;
      #   dynamic-workspaces = true;
      #   workspaces-only-on-primary = true;
      # };
    }
    // dconfKeybinds;
}
