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
    # https://github.com/nvarner/typst-lsp/pull/515
    # typst-lsp
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
    # https://github.com/NixOS/nixpkgs/pull/335559
    # nodePackages.vscode-langservers-extracted
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
    zig
    zls
    just
    cookiecutter
  ];
}
