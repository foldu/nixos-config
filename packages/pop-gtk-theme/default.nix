{ lib
, stdenv
, fetchFromGitHub
, meson
, ninja
, sassc
, gtk3
, inkscape
, optipng
, gtk-engine-murrine
, gdk-pixbuf
, librsvg
, python3
}:

stdenv.mkDerivation rec {
  pname = "pop-gtk-theme";
  version = "unstable-2021-04-28";

  src = fetchFromGitHub {
    owner = "pop-os";
    repo = "gtk-theme";
    rev = "6cec78b18b9c4f98777732c967ff83ba590ada0f";
    sha256 = "sha256-tWQ/3oyZXo5zmXOIpHBVd2+RWS9GeS0puw9N87ME/T8=";
  };

  nativeBuildInputs = [
    meson
    ninja
    sassc
    gtk3
    inkscape
    optipng
    python3
  ];

  buildInputs = [
    gdk-pixbuf
    librsvg
  ];

  propagatedUserEnvPkgs = [
    gtk-engine-murrine
  ];

  postPatch = ''
    patchShebangs .

    for file in $(find -name render-\*.sh); do
      substituteInPlace "$file" \
        --replace 'INKSCAPE="/usr/bin/inkscape"' \
                  'INKSCAPE="${inkscape}/bin/inkscape"' \
        --replace 'OPTIPNG="/usr/bin/optipng"' \
                  'OPTIPNG="${optipng}/bin/optipng"'
    done
  '';
}
