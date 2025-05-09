{ pkgs, ... }:
{
  home.packages = with pkgs; [
    powershell
    powershell-editor-services
  ];
}
