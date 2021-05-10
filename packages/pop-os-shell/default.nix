{ stdenv, fetchFromGitHub, nodePackages, glib, substituteAll, gjs, lib }:

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
  ];

  makeFlags = [ "INSTALLBASE=$(out)/share/gnome-shell/extensions PLUGIN_BASE=$(out)/share/pop-shell/launcher SCRIPTS_BASE=$(out)/bin" ];

  postInstall = ''
    chmod +x $out/share/gnome-shell/extensions/pop-shell@system76.com/floating_exceptions/main.js
    chmod +x $out/share/gnome-shell/extensions/pop-shell@system76.com/color_dialog/main.js
    rm -rf $out/bin
  '';
}
