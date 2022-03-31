{ config, lib, pkgs, ... }: {

  home.packages = with pkgs; [
    rustup
    cargo-deny
    cargo-outdated
    cargo-edit
    cargo-flamegraph
    cargo-bloat
  ];

  systemd.user = {
    services.rustup-update = {
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.rustup}/bin/rustup update";
      };
    };
    timers.rustup-update = {
      Timer = {
        OnCalendar = "weekly";
      };
    };
  };

  # use a linker that doesn't suck
  home.file.".cargo/config".text = ''
    [target.x86_64-unknown-linux-gnu]
    rustflags = [
        "-C", "link-arg=-fuse-ld=lld",
    ]
  '';
}
