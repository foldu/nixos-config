{ stdenv, fetchFromGitHub, fetchpatch, nodePackages, glib, substituteAll, gjs, lib }:

stdenv.mkDerivation rec {
  pname = "pop-os-shell";
  version = "afb4f12df1b8ca24dda6aff7ea157bedb8fff208";

  src = fetchFromGitHub {
    owner = "pop-os";
    repo = "shell";
    rev = version;
    sha256 = "sha256-M52xKrYilnbf0wbV8fYOq9gT6z+YRisD37U4G/tXs98=";
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
