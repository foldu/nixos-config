# Downstream fixes for bugs that are already fixed upstream but not yet in the
# nixpkgs revision we track. Everything here is temporary: each entry says what
# breaks without it, where it was fixed upstream, and how to check whether our
# pin has that fix yet.
#
#   P=$(nix eval --raw --impure --expr '(builtins.getFlake (toString ./.)).inputs.nixpkgs.outPath')
#
# then grep the quoted path for the code the upstream fix adds — if it is there
# (exit status 0), the entry can go.
final: prev: {
  # Without this, venus' system.modulesTree fails to build:
  #   cat: extra/framework_laptop.ko.cer: No such file or directory
  # nixos-hardware enables hardware.framework.enableKmod by default, so
  # framework-laptop-kmod is an extra kernel module package. The package
  # installs its .ko by hand, which bypasses Kbuild's modules_install — the
  # step that signs modules with kmodigest and writes the per-module .ko.cer
  # that the modules aggregator then concatenates into modules.cer.
  # Upstream fix: https://github.com/NixOS/nixpkgs/pull/575818 (82139be7,
  # 2026-10-20). It is in nixos-unstable-small, but landed six hours after
  # nixos-unstable last advanced (02c087f, 2026-10-20 13:28 UTC).
  # Check: grep -q installTargets "$P/pkgs/os-specific/linux/framework-laptop-kmod/default.nix"
  linuxPackages_latest = prev.linuxPackages_latest.extend (
    _: kernelPrev: {
      framework-laptop-kmod = kernelPrev.framework-laptop-kmod.overrideAttrs (oldAttrs: {
        makeFlags = oldAttrs.makeFlags ++ [
          "INSTALL_MOD_PATH=${placeholder "out"}"
          "INSTALL_MOD_DIR=extra"
          "DEPMOD=true"
        ];
        installTargets = [ "modules_install" ];
        # drop the hand-rolled installPhase so Kbuild's install target runs
        installPhase = null;
      });
    }
  );
}
