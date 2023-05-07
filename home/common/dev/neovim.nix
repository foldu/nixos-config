{ pkgs, inputs, ... }: {
  systemd.user.sessionVariables = {
    EDITOR = "nvim";
    NIX_GCC = "${pkgs.gcc}/bin/gcc";
  };
  home.packages = with pkgs; [
    inputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim

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
