{ lib
, rustPlatform
, fetchFromGitHub
, withLsp ? true
}:

rustPlatform.buildRustPackage {
  pname = "taplo";
  version = "unstable-2023-06-22";

  src = fetchFromGitHub {
    owner = "tamasfe";
    repo = "taplo";
    rev = "68979f0be72bfcccdfe7114e5b8182bc5d26ad16";
    pname = "taplo-cli";
    sha256 = "sha256-Mka3x23UGqGozgFgM/rSk8TiBLa9AvA2eqU7vaZblZg=";
  };

  cargoSha256 = "sha256-9hWlya0X40fFQiSSMOst/JBfeNJABfSdmdJZIuTtZtQ=";


  buildFeatures = lib.optional withLsp "lsp";
}
