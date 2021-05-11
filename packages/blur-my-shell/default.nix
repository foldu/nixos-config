{ lib
, stdenv
, fetchFromGitHub
, glib
}:
stdenv.mkDerivation rec {
  pname = "blur-my-shell";
  version = "10";

  src = fetchFromGitHub {
    owner = "aunetx";
    repo = "blur-my-shell";
    rev = "v${version}";
    sha256 = "sha256-hJJKCfvKzyf6P7P+N1tCGdRRXQgf9IlmcDumZb64yXg=";
  };

  uuid = "blur-my-shell@aunetx";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/gnome-shell/extensions/${uuid}
    cp -r build/* $out/share/gnome-shell/extensions/${uuid}
    runHook postInstall
  '';

  nativeBuildInputs = [
    glib
  ];
}
