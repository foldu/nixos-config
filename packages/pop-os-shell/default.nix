{ stdenv, fetchFromGitHub, fetchpatch, nodePackages, glib, substituteAll, gjs, lib }:

stdenv.mkDerivation rec {
  pname = "pop-os-shell";
  version = "9507dc38f75f56e657cf071d5f8dc578c5dc9352";

  src = fetchFromGitHub {
    owner = "pop-os";
    repo = "shell";
    rev = version;
    sha256 = "sha256-9Z1SDg9TWdk5W22FkGYGQW1iMdS+T+hUpzZMW7whKZg=";
  };

  nativeBuildInputs = [ glib nodePackages.typescript gjs ];

  buildInputs = [ gjs ];

  patches = [
    ./fix-gjs.patch
    (fetchpatch {
      url = "https://github.com/pop-os/shell/commit/1e24cd7ed64b138f1aa8b2aceb31ce9f55eaf594.patch";
      sha256 =
        "sha256-V18/7K45QAeVM4SkchHKUvvHww8oaet/tB5ReoU0Vr8=";

    })
  ];

  makeFlags = [ "INSTALLBASE=$(out)/share/gnome-shell/extensions PLUGIN_BASE=$(out)/share/pop-shell/launcher SCRIPTS_BASE=$(out)/bin" ];

  postInstall = ''
    chmod +x $out/share/gnome-shell/extensions/pop-shell@system76.com/floating_exceptions/main.js
    chmod +x $out/share/gnome-shell/extensions/pop-shell@system76.com/color_dialog/main.js
    rm -rf $out/bin
  '';
}
