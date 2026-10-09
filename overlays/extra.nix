{ inputs, ... }:
final: prev: {
  domitian = prev.callPackage ../packages/domitian { };
  helium = prev.callPackage ../packages/helium { };
  ghidra-mcp = prev.callPackage ../packages/ghidra-mcp { };
  photocraft = prev.callPackage ../packages/photocraft { };
  gitlab-mirror = prev.callPackage ../packages/gitlab-mirror { };
  ovh-dns = prev.callPackage ../packages/ovh-dns { };
  dsh = prev.callPackage ../packages/dsh {
    dsh = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system}.dsh;
  };
}
