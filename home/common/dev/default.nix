{pkgs, ...}: {
  imports = [
    ./rust.nix
    ./neovim.nix
    ./helix.nix
  ];

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
  ];
}
