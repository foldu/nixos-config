final: prev: {
  domitian = prev.callPackage ../packages/domitian { };
  helium = prev.callPackage ../packages/helium { };
  ghidra-mcp = prev.callPackage ../packages/ghidra-mcp { };
}
