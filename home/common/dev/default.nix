{ pkgs, ... }:
{
  imports = [
    ./rust.nix
    ./helix.nix
  ];

  systemd.user.sessionVariables = {
    EDITOR = "hx";
  };

  home.packages = with pkgs; [
    tokei
    minicom
    gdb
    clang-tools
    llvmPackages_latest.lld
    llvmPackages_latest.clang
    sqlite-interactive

    zed
    ast-grep
    android-studio
    go
    gopls
    arduino-cli
    black
    ccls
    nixfmt-rfc-style
    typst
    typst-fmt
    tinymist
    typstyle
    typst-live
    yarn
    gnumake
    nixd
    nodePackages.bash-language-server
    nodePackages.prettier
    nodePackages.typescript
    nodePackages.typescript-language-server
    # nodePackages.eslint
    nodePackages.yaml-language-server
    nodePackages.vscode-langservers-extracted
    plantuml
    tree-sitter
    taplo-cli
    shellcheck
    shfmt
    stylua
    sumneko-lua-language-server
    texlab
    ruff-lsp
    # based on what?
    basedpyright
    markdownlint-cli2
    jdt-language-server
    jdk21
    zig
    zls
    just
    cookiecutter
  ];
}
