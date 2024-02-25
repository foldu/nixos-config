{ pkgs, ... }:
{
  home.packages = with pkgs; [
    rustup
    cargo-deny
    cargo-outdated
    cargo-flamegraph
    cargo-bloat
  ];

  # use a linker that doesn't suck
  home.file.".cargo/config.toml".text = ''
    [target.x86_64-unknown-linux-gnu]
    rustflags = [
        "-C", "link-arg=-fuse-ld=lld",
    ]
  '';
}
