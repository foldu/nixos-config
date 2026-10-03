{ inputs, ... }:
final: prev: {
  domitian = prev.callPackage ../packages/domitian { };
  helium = prev.callPackage ../packages/helium { };
  ghidra-mcp = prev.callPackage ../packages/ghidra-mcp { };
  dsh = prev.callPackage ../packages/dsh {
    dsh = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system}.dsh;
  };
}
