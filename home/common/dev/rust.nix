{ pkgs, ... }:
{
  home.packages = with pkgs; [
    rustup
    cargo-deny
    cargo-outdated
    cargo-flamegraph
    cargo-bloat
  ];

  home.file.".cargo/config.toml".text = ''
    [target.x86_64-unknown-linux-gnu]
    linker = "clang"
    rustflags = ["-C", "link-arg=-fuse-ld=${pkgs.mold}/bin/mold"]
  '';
}
