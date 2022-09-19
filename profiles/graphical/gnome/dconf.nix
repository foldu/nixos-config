{ pkgs, lib, ... }: {
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "xhide";
      runtimeInputs = with pkgs; [ kitty xdotool ];
      text = builtins.readFile ./xhide.sh;
    })
  ];

  home-manager.users.barnabas = { lib, config, ... }: {
    dconf.enable = true;
    dconf.settings =
      let
        customKeybinds = [
          {

            binding = "<Super>t";
            command = "kitty --single-instance";
            name = "Open terminal";
          }
          {
            binding = "<Super>d";
            command = "xhide --cmd com.github.taiko2k.tauonmb --name tauon --windowclass \"Tauon Music Box\"";
            name = "Open music player";
          }
          {
            binding = "<Super>z";
            command =
              let
                script = pkgs.writeText "floating-term" ''
                  #!/bin/sh
                  session=$(
                      cat <<EOF
                  cd ~/nixos-config/
                  launch fish
                  new_tab
                  cd ~/
                  launch fish
                  EOF
                  )

                  echo "$session" | kitty --class "Floating Term" --session -
                '';
              in
              "xhide --cmd \"sh ${script}\" --name floating-term --windowclass \"Floating Term\"";
            name = "Open floating terminal";
          }
        ];
        keybindRange = lib.lists.range 0 (lib.lists.length customKeybinds);
        dconfKeybinds = builtins.listToAttrs
          (lib.flip map (lib.lists.zipLists keybindRange customKeybinds) ({ fst, snd }: {
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

        "org/gnome/shell/extensions/user-theme" = {
          name = "Yaru-dark";
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
          custom-keybindings = dconfKeybindPaths;
          email = [ "<Super>e" ];
          home = [ "<Super>f" ];
          rotate-video-lock-static = "@as []";
          screensaver = [ "<Super>Escape" ];
          www = [ "<Super>b" ];
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
            "just-perfection-desktop@just-perfection"
            "pop-shell@system76.com"
            "user-theme@gnome-shell-extensions.gcampax.github.com"
            "gnome-ui-tune@itstime.tech"
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
          workspace-switcher-should-show = true;
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

        "org/gnome/shell/extensions/gnome-ui-tune" = {
          hide-search = false;
          increase-thumbnails-size = false;
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
      } // dconfKeybinds;
  };
}
