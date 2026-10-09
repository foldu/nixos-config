{
  lib,
  buildGoModule,
}:
buildGoModule {
  pname = "ovh-dns";
  version = "0.1.0";

  src = lib.cleanSource ./.;

  # sops is linked in as a library, so there is no sops binary to wrap and
  # nothing to put on PATH
  vendorHash = "sha256-QqAd0Mja1HevDSG1zadUiexTGyQ+zn2kT3IrKL74rVs=";

  ldflags = [
    "-s"
    "-w"
  ];

  meta = {
    description = "Edit OVH DNS zones with the credentials from `caddy/env` in secrets/secrets.yaml, decrypted through sops";
    mainProgram = "ovh-dns";
  };
}
