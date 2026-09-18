{
  lib,
  stdenv,
  fetchurl,
  unzip,
}:
# GhidraMCP Ghidra extension — the HTTP server the pi MCP bridge talks to.
# Prebuilt release zip: building it from source needs Maven against Ghidra's JARs.
# extension.properties pins the Ghidra version it was built against, so this has to
# move in lockstep with ghidra in nixpkgs (12.1.2).
stdenv.mkDerivation (finalAttrs: {
  pname = "GhidraMCP";
  version = "6.0.0";

  src = fetchurl {
    url = "https://github.com/bethington/ghidra-mcp/releases/download/v${finalAttrs.version}/GhidraMCP-${finalAttrs.version}.zip";
    hash = "sha256-hncx3ifVFDYyoBCUO5B6ZIXdVNDhlyni+F7p9pLJmHM=";
  };

  nativeBuildInputs = [ unzip ];

  # Layout ghidra.withExtensions expects. The unpacked source root is GhidraMCP/.
  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/ghidra/Ghidra/Extensions/GhidraMCP
    cp -r . $out/lib/ghidra/Ghidra/Extensions/GhidraMCP/
    # Same as nixpkgs buildGhidraExtension: stop Ghidra writing its lock file to the store.
    touch $out/lib/ghidra/Ghidra/Extensions/GhidraMCP/.dbDirLock
    runHook postInstall
  '';

  meta = {
    description = "Ghidra extension running an embedded HTTP server for the GhidraMCP bridge";
    homepage = "https://github.com/bethington/ghidra-mcp";
    license = lib.licenses.asl20;
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
    platforms = lib.platforms.unix;
  };
})
