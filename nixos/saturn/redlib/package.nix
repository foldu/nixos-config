{
  lib,
  stdenv,
  cacert,
  nixosTests,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "redlib";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "redlib-org";
    repo = "redlib";
    rev = "9afe886c2c120bd5b9c24dd33341a3a70792b25b";
    hash = "sha256-IqiKK0CwES5RZapqqUrRDKsLopH2r/LubnKt3UP0fp4=";
  };

  useFetchCargoVendor = true;

  cargoHash = "sha256-WTP6RLn/JMDb+m5LUBuECaFGmMYnzeCQjiVjq3Wujfo=";

  buildInputs = lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.Security
  ];

  doCheck = false;

  checkFlags = [
    # All these test try to connect to Reddit.
    "--skip=test_fetching_subreddit_quarantined"
    "--skip=test_fetching_nsfw_subreddit"
    "--skip=test_fetching_ws"

    "--skip=test_obfuscated_share_link"
    "--skip=test_share_link_strip_json"

    "--skip=test_localization_popular"
    "--skip=test_fetching_subreddit"
    "--skip=test_fetching_user"

    "--skip=test_gated_and_quarantined"

    "--skip=test_compress_response"
    "--skip=test_private_sub"

    # These try to connect to the oauth client
    "--skip=test_oauth_client"
    "--skip=test_oauth_client_refresh"
    "--skip=test_oauth_token_exists"
    "--skip=test_oauth_headers_len"
  ];

  env = {
    SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
  };

  passthru.tests = {
    inherit (nixosTests) redlib;
  };

  meta = {
    changelog = "https://github.com/redlib-org/redlib/releases/tag/v${version}";
    description = "Private front-end for Reddit (Continued fork of Libreddit)";
    homepage = "https://github.com/redlib-org/redlib";
    license = lib.licenses.agpl3Only;
    mainProgram = "redlib";
    maintainers = with lib.maintainers; [ soispha ];
  };
}
