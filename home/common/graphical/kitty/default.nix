{ pkgs, getSettings, ... }:
let
  configSettings = getSettings pkgs;
in
{
  programs.kitty = {
    enable = true;
    font = {
      name = configSettings.font.devMonospace.name;
      size = 12;
    };
    keybindings = {
      #"ctrl+c" = "copy_or_interrupt";
      #"ctrl+v" = "paste_from_clipboard";
      # "ctrl+shift+k" = "previous_window";
      # "ctrl+shift+j" = "next_window";
      "ctrl+shift+t" = "new_tab_with_cwd";
      "ctrl+shift+enter" = "new_window_with_cwd";
    };
    settings = {
      tab_bar_edge = "top";
      tab_bar_min_tabs = 2;

      # shouldn't these be a part of the colorscheme?
      active_border_color = "#FFA066";
      inactive_border_color = "#15161E";
      window_border_width = "1pt";
      window_padding_width = "1";

      show_hyperlink_targets = "yes";

      # allow_remote_control = "yes";

      notify_on_cmd_finish = "unfocused";
      shell_integration = "no-rc no-cursor";

      enabled_layouts = "splits";
      # tab_bar_edge = "bottom";
      tab_bar_margin_height = "0 7.5";
      tab_bar_style = "slant";
      tab_bar_align = "left";
      tab_title_max_length = "0";

      # tab_title_template = " {tab.active_exe} {title[title.rfind('/')+1:]}";
      # active_tab_title_template = " {tab.active_exe} {title[title.rfind('/')+1:]}";
      tab_title_template = " {tab.active_exe} {title}";
      active_tab_title_template = " {tab.active_exe} {title}";

      active_tab_font_style = "normal";
      inactive_tab_font_style = "normal";

      enable_audio_bell = "no";
      disable_ligatures = "always";
      update_check_interval = 0;
      linux_display_server = "wayland";
      wayland_enable_ime = "no";
      input_delay = 0;
      repaint_delay = 2;
      sync_to_monitor = 0;
      scrollback_fill_enlarged_window = "yes";
      #wayland_titlebar_color = "#222222";
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
      inactive_tab_background  #15161E
      inactive_tab_foreground #C8C093
      tab_bar_background #15161E

      # normal
      color0 #16161D

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

  xdg.configFile."kitty/open-actions.conf".source = ./open-actions.conf;
}
