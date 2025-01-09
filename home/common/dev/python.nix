{ pkgs, ... }:
{
  home.packages = with pkgs; [
    python312
    uv
    basedpyright # based on what?
    ruff
  ];
}
