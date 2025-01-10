{
  pkgs,
  lib,
  kernel ? pkgs.linuxPackages_latest.kernel,
}:

pkgs.stdenv.mkDerivation {
  pname = "amdgpu-kernel-module";
  inherit (kernel)
    src
    version
    postPatch
    nativeBuildInputs
    ;

  kernel_dev = kernel.dev;
  kernelVersion = kernel.modDirVersion;

  modulePath = "drivers/gpu/drm/amd/amdgpu";

  patches = [
    ./1c86c81a86c60f9b15d3e3f43af0363cf56063e7.patch
    ./ab75a0d2e07942ae15d32c0a5092fd336451378c.patch
    ./b8d6daffc871a42026c3c20bff7b8fa0302298c1.patch
  ];

  buildPhase = ''
    BUILT_KERNEL=$kernel_dev/lib/modules/$kernelVersion/build

    cp $BUILT_KERNEL/Module.symvers .
    cp $BUILT_KERNEL/.config        .
    cp $kernel_dev/vmlinux          .

    make "-j$NIX_BUILD_CORES" modules_prepare
    make "-j$NIX_BUILD_CORES" M=$modulePath modules
  '';

  installPhase = ''
    make \
      INSTALL_MOD_PATH="$out" \
      XZ="xz -T$NIX_BUILD_CORES" \
      M="$modulePath" \
      modules_install
  '';

  meta = {
    description = "AMD GPU kernel module";
    license = lib.licenses.gpl3;
  };
}
