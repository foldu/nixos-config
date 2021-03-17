{ stdenv, fetchFromGitHub, nodePackages, glib, substituteAll, gjs }:

stdenv.mkDerivation rec {
  pname = "pop-os-shell";
  version = "77650a9aafa2f7adc328424e36dc91705411feb4";

  src = fetchFromGitHub {
    owner = "pop-os";
    repo = "shell";
    rev = version;
    sha256 = "sha256-z9qJ9fG0mr7czhEDIhHH6Kb99eowzeX/x6LPgehDzjU=";
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

   meta = with stdenv.lib; {
    description = "Keyboard-driven layer for GNOME Shell";
    license = licenses.gpl3Only;
    homepage = "https://github.com/pop-os/shell";
    platforms = platforms.linux;
    maintainers = with maintainers; [ remunds ];
  };
}
