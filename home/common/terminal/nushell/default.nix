{ pkgs, ... }: {
  home.packages = [
    pkgs.carapace
  ];

  programs.nushell.enable = true;

  xdg.configFile."nushell" = {
    source = ./config;
    recursive = true;
  };
}
