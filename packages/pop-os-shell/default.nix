{ stdenv, fetchFromGitHub, fetchpatch, nodePackages, glib, substituteAll, gjs, lib }:

stdenv.mkDerivation rec {
  pname = "pop-os-shell";
  version = "e7f30249a18317de3a54dc185e3a547ee4a74022";

  src = fetchFromGitHub {
    owner = "pop-os";
    repo = "shell";
    rev = version;
    sha256 = "sha256-TULRwO+23V0/9Du8nolWfjWz9TLg2V3COneZVB+DLX0=";
  };

  nativeBuildInputs = [ glib nodePackages.typescript gjs ];

  buildInputs = [ gjs ];

  preBuildHook = ''
    find . -name '*.ts' -exec sed -i -E 's|^#!/usr/bin/gjs|#!/usr/bin/env gjs|' \{\} \;
  '';

  patches = [ ./gnome-41.patch ];

  makeFlags = [ "INSTALLBASE=$(out)/share/gnome-shell/extensions PLUGIN_BASE=$(out)/share/pop-shell/launcher SCRIPTS_BASE=$(out)/bin" ];

  postInstall = ''
    chmod +x $out/share/gnome-shell/extensions/pop-shell@system76.com/floating_exceptions/main.js
    chmod +x $out/share/gnome-shell/extensions/pop-shell@system76.com/color_dialog/main.js
    rm -rf $out/bin
  '';
}
