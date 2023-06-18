{ pkgs, ... }: {
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
    #openocd
    clang-tools
    llvmPackages_latest.lld
    llvmPackages_latest.clang
    sqlite-interactive
    # broken
    #litecli
    #pgcli

    arduino-cli
    black
    ccls
    # llvmPackages_latest.lldb
    # llvmPackages_latest.bintools
    nixpkgs-fmt
    yarn
    gnumake
    nil
    nodePackages.bash-language-server
    nodePackages.prettier
    nodePackages.pyright
    nodePackages.typescript
    nodePackages.typescript-language-server
    nodePackages.eslint
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
  ];
}
