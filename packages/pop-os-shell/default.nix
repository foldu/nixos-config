{ stdenv, fetchFromGitHub, fetchpatch, nodePackages, glib, substituteAll, gjs, lib }:

stdenv.mkDerivation rec {
  pname = "pop-os-shell";
  version = "c7390c8c370c81aaad285b47cd3915a7c4708b98";

  src = fetchFromGitHub {
    owner = "pop-os";
    repo = "shell";
    rev = version;
    sha256 = "sha256-8ZdWitJ0hNS6iaCs/0gM+FNSRCG27Tpu2QWh4OKzyEs=";
  };

  nativeBuildInputs = [ glib nodePackages.typescript gjs ];

  buildInputs = [ gjs ];

  preBuildHook = ''
    find . -name '*.ts' -exec sed -i -E 's|^#!/usr/bin/gjs|#!/usr/bin/env gjs|' \{\} \;
  '';

  makeFlags = [ "INSTALLBASE=$(out)/share/gnome-shell/extensions PLUGIN_BASE=$(out)/share/pop-shell/launcher SCRIPTS_BASE=$(out)/bin" ];

  postInstall = ''
    chmod +x $out/share/gnome-shell/extensions/pop-shell@system76.com/floating_exceptions/main.js
    chmod +x $out/share/gnome-shell/extensions/pop-shell@system76.com/color_dialog/main.js
    rm -rf $out/bin
  '';
}
