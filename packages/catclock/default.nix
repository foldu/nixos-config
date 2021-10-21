{ lib
, stdenv
, fetchFromGitHub
, motif
, libX11
, libXt
, libXext
}:
let 
  version = "9de77d05e04bc463bdbd8cfe1f9247042369e3f9"; 
in
stdenv.mkDerivation {
  pname = "catclock";
  inherit version;
  src = fetchFromGitHub {
      owner = "BarkyTheDog";
      repo = "catclock";
      rev = version;
      sha256 = "sha256-aKJc42ZMoI4wc2kHaJlpQieLSvMg0hJAyJaaM72NpEI=";
  };
  buildInputs = [
    motif
    libX11
    libXt
    libXext
  ];
  installPhase = ''
    mkdir -p "$out/bin"
    cp xclock "$out/bin/catclock"
  '';
}
