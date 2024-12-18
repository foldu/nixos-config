{ pkgs, ... }:
{
  imports = [
    ./rust.nix
  ];

  systemd.user.sessionVariables = {
    EDITOR = "nvim";
  };

  home.packages = with pkgs; [
    # editors
    # zed-editor
    tokei
    minicom
    gdb
    # tools
    sqlite-interactive
    yarn
    gnumake
    just
    cookiecutter
    plantuml

    # editor tools
    ast-grep
    tree-sitter

    # c/c++ native tools
    clang-tools
    llvmPackages_latest.lld
    llvmPackages_latest.clang

    # go
    go
    gopls
    black
    ccls

    # typst
    typst
    typst-fmt
    tinymist
    typstyle
    typst-live

    # tex
    texlab

    # nix
    nixd
    nixfmt-rfc-style

    # shell
    nodePackages.bash-language-server
    shellcheck
    shfmt

    # webshit
    nodePackages.prettier
    nodePackages.typescript
    nodePackages.typescript-language-server
    nodePackages.eslint
    nodePackages.vscode-langservers-extracted

    # yaml
    nodePackages.yaml-language-server
    taplo-cli
    # lua
    stylua
    sumneko-lua-language-server

    # python
    basedpyright # based on what?
    ruff-lsp
    # markdown
    marksman
    markdownlint-cli2

    # java
    jdt-language-server
    jdk21
    maven

    # :goat
    zig
    zls
  ];
}
