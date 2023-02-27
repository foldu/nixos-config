{ pkgs, configSettings, lib, inputs, ... }: {
  programs.kitty = {
    enable = true;
    font = {
      name = configSettings.font.devMonospace.name;
      size = 12;
    };
    keybindings = {
      #"ctrl+c" = "copy_or_interrupt";
      #"ctrl+v" = "paste_from_clipboard";
      "ctrl+shift+[" = "previous_tab";
      "ctrl+shift+]" = "next_tab";
      "ctrl+shift+k" = "previous_window";
      "ctrl+shift+j" = "next_window";
      "ctrl+shift+t" = "new_tab_with_cwd";
      "ctrl+shift+enter" = "new_window_with_cwd";
    };
    settings = {
      tab_bar_edge = "top";
      tab_bar_min_tabs = 1;

      # shouldn't these be a part of the colorscheme?
      active_border_color = "#FFA066";
      inactive_border_color = "#15161E";

      window_border_width = "1pt";
      window_padding_width = "1";
      enabled_layouts = "tall,stack";
      tab_bar_style = "custom";
      enable_audio_bell = "no";
      disable_ligatures = "always";
      update_check_interval = 0;
      linux_display_server = "x11";
      wayland_titlebar_color = "#222222";
    };
    extraConfig = ''
      # vim:ft=kitty

      ## name: Kanagawa
      ## license: MIT
      ## author: Tommaso Laurenzi
      ## upstream: https://github.com/rebelot/kanagawa.nvim/


      background #1F1F28
      foreground #DCD7BA
      selection_background #2D4F67
      selection_foreground #C8C093
      url_color #72A7BC
      cursor #C8C093

      # Tabs
      active_tab_background #1F1F28
      active_tab_foreground #C8C093
      inactive_tab_background  #1F1F28
      inactive_tab_foreground #727169
      tab_bar_background #15161E

      # normal
      color0 #090618
      color1 #C34043
      color2 #76946A
      color3 #C0A36E
      color4 #7E9CD8
      color5 #957FB8
      color6 #6A9589
      color7 #C8C093

      # bright
      color8  #727169
      color9  #E82424
      color10 #98BB6C
      color11 #E6C384
      color12 #7FB4CA
      color13 #938AA9
      color14 #7AA89F
      color15 #DCD7BA


      # extended colors
      color16 #FFA066
      color17 #FF5D62
    '';
  };

  xdg.configFile."kitty/tab_bar.py".source = ./tab_bar.py;
  xdg.configFile."kitty/open-actions.conf".source = ./open-actions.conf;
}
