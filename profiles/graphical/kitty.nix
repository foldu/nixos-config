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
      "ctrl+shift+j" = "previous_tab";
      "ctrl+shift+k" = "next_tab";
    };
    settings = {
      tab_bar_style = "powerline";
      enable_audio_bell = "no";
      disable_ligatures = "always";
      update_check_interval = 0;
      linux_display_server = "wayland";
      wayland_titlebar_color = "#222222";
    };
    extraConfig = lib.readFile "${inputs.kanagawa-theme}/extras/kanagawa.conf";
  };
}
