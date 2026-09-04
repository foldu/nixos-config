{
  lib,
  buildGoModule,
}:
buildGoModule rec {
  pname = "hassctl";
  version = "0.1.0";

  src = lib.cleanSource ./.;

  # no vendored deps in the repo — go.sum is the source of truth; the build
  # runs `go mod vendor` and verifies the result against vendorHash
  vendorHash = "sha256-cLGdgQJ+3Ez8O6YQyfcAmkk9kCIiTkW77sTRMxTpHi4=";

  ldflags = [
    "-s"
    "-w"
  ];

  meta = {
    description = "HTTP control endpoint for waking/powering off/checking LAN devices, deployed on netbird-gw (see README.md)";
    mainProgram = "hassctl";
  };
}
