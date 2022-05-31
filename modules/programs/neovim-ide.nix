# TODO: make this a home-manager module instead
{ pkgs, config, lib, ... }:
with lib;

let
  cfg = config.programs.neovim-ide;
  cleaned-neovim = pkgs.neovim-nightly.overrideAttrs (oldAttrs: {
    # the default colorthemes kind of suck so just kill them
    postInstall = ''
      find $out/share/nvim/runtime/colors -not -name 'default.vim' -type f -delete
    '';
  });
in
{
  # TODO: clone config from flake
  options = {
    programs.neovim-ide = {
      enable = mkEnableOption "Enable riced neovim with language servers and autoformatters";
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cleaned-neovim
      # for rocks functionality in packer
      luajitPackages.luarocks

      black
      ccls
      llvmPackages_latest.lldb
      llvmPackages_latest.bintools
      nixpkgs-fmt
      # to install prettierd with
      nodejs
      yarn
      gnumake
      nodePackages.bash-language-server
      nodePackages.prettier
      nodePackages.pyright
      nodePackages.typescript
      nodePackages.typescript-language-server
      nodePackages.yaml-language-server
      nodePackages.vscode-langservers-extracted
      plantuml
      (ruby_3_0.withPackages (p: with p; [
        pry
        solargraph
        sqlite3
        nokogiri
        httpclient
        slop
        clamp
        rubocop
      ]))
      rustfmt
      taplo-cli
      shellcheck
      shfmt
      stylua
      sumneko-lua-language-server
      texlab
    ];
  };
}
