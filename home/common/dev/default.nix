{ pkgs, ... }:
{
  imports = [
    ./rust.nix
    ./python.nix
  ];

  systemd.user.sessionVariables = {
    EDITOR = "nvim";
  };

  home.packages = with pkgs; [
    # editors
    # zed-editor
    tokei
    gdb
    # tools
    sqlite-interactive
    yarn
    gnumake
    just
    cookiecutter
    plantuml
    glab

    # editor tools
    ast-grep
    tree-sitter

    # c/c++ native tools
    clang-tools
    llvmPackages_latest.lld
    llvmPackages_latest.clang
    cmake
    neocmakelsp
    cmake-lint
    cmake-format

    # go
    go
    gopls
    black

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
    vue-language-server
    nodejs
    vtsls
    biome

    # yaml
    nodePackages.yaml-language-server
    taplo-cli
    # lua
    stylua
    sumneko-lua-language-server

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
