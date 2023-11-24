{ pkgs, ... }: {
  home.packages = [
    pkgs.carapace
    pkgs.zoxide
  ];

  programs.nushell.enable = true;

  xdg.configFile."nushell" = {
    source = ./config;
    recursive = true;
  };

  # xdg.configFile."nushell/br.nu".source = pkgs.runCommandLocal "br.nu" { } ''
  #   ${pkgs.broot}/bin/broot --print-shell-function nushell > $out
  # '';
}
