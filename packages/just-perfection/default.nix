{ stdenv,lib, fetchFromGitLab, glib }:

stdenv.mkDerivation rec {
  pname = "just-perfection";
  version = "unstable-2021-05-11";

  src = fetchFromGitLab {
    domain = "gitlab.gnome.org";
    owner = "jrahmatzadeh";
    repo = "just-perfection";
    rev = "a7da77417778907cd1bee24cb111968313e8c793";
    sha256 = "sha256-8WWGpmMMbLx+PBHgHNwj5CEMUNgNAg7dzwYEemBKbeA=";
  };

  nativeBuildInputs = [ glib ];

  uuid = "just-perfection-desktop@just-perfection";

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
