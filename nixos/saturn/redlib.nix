{
  config,
  pkgs,
  ...
}:

# stolen from https://github.com/redlib-org/redlib/pull/544#issuecomment-4230094820
let
  src = pkgs.fetchFromGitHub {
    owner = "Silvenga";
    repo = "redlib";
    rev = "af002ab216d271890e715c2d3413f7193c07c640";
    hash = "sha256-Ny/pdBZFgUAV27e3wREPV8DUtP3XfMdlw0T01q4b70U=";
  };
  # Use Silvenga's wreq fork (redlib-org/redlib#544) which uses BoringSSL
  # to emulate browser TLS fingerprints and evade bot detection
  redlib-fork = pkgs.redlib.overrideAttrs (oldAttrs: {
    version = "0.36.0-unstable-2026-04-04";
    inherit src;
    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit src;
      name = "redlib-0.36.0-unstable-2026-04-04-vendor";
      hash = "sha256-eO3c7rlFna3DuO31etJ6S4c7NmcvgvIWZ1KVkNIuUqQ=";
    };
    # BoringSSL (via boring-sys2) needs cmake, go, git, perl, and libclang for bindgen
    nativeBuildInputs =
      (oldAttrs.nativeBuildInputs or [ ])
      ++ (with pkgs; [
        cmake
        go
        perl
        git
        rustPlatform.bindgenHook
      ]);
    checkFlags = (oldAttrs.checkFlags or [ ]) ++ [
      "--skip=oauth::tests::test_generic_web_backend"
      "--skip=oauth::tests::test_mobile_spoof_backend"
    ];
  });
in
{
  services.redlib = {
    enable = true;
    package = redlib-fork;
    port = 7777;
  };

  services.caddy.extraConfig = ''
    reddit.home.5kw.li {
      reverse_proxy localhost:${toString config.services.redlib.port}
    }
  '';
}
