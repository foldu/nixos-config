{ config, lib, pkgs, ... }: {

  home.packages = with pkgs; [
    #(
    #  pkgs.rust-bin.nightly.latest.minimal.override {
    #    extensions = [
    #      "rust-src"
    #      "clippy"
    #    ];
    #    targets = [
    #      "x86_64-unknown-linux-musl"
    #      "aarch64-unknown-linux-gnu"
    #      "wasm32-unknown-unknown"
    #      "wasm32-wasi"
    #    ];
    #  }
    #)
    rustc
    cargo
    rust-analyzer
    rustfmt
    cargo-deny
    cargo-outdated
    cargo-edit
    cargo-flamegraph
    cargo-bloat
  ];

  # use a linker that doesn't suck
  home.file.".cargo/config".text = ''
    [target.x86_64-unknown-linux-gnu]
    rustflags = [
        "-C", "link-arg=-fuse-ld=lld",
    ]
  '';
}
