{ stdenv, lib, fetchFromGitHub, glib }:

stdenv.mkDerivation rec {
  pname = "gnome-ui-tune";
  version = "v1.6.3";

  src = fetchFromGitHub {
    owner = "axxapy";
    repo = "gnome-ui-tune";
    rev = version;
    sha256 = "sha256-8H59ZvvrH0Fjlw2+SpPkNCGaUqH351VifSUkkGn0/Ic=";
  };

  nativeBuildInputs = [ glib ];

  uuid = "gnome-ui-tune@itstime.tech";

  buildPhase = ''
    runHook preBuild
    glib-compile-schemas ./schemas
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/gnome-shell/extensions/${uuid}
    cp -r * $out/share/gnome-shell/extensions/${uuid}
    runHook postInstall
  '';
}
