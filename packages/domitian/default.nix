{ fetchzip, stdenv, lib }:
fetchzip {
  name = "domitian-1.0";
  url = "http://mirrors.ctan.org/fonts/domitian.zip";
  sha256 = "sha256-Ef5J6Ff0wT2mXgJrHuJAYKu9eCtWtIaX9GpvP3lQDRU=";

  postFetch = ''
    mkdir -p $out/share/fonts
    unzip -j $downloadedFile 'domitian/opentype/*.otf' -d $out/share/fonts/opentype
  '';
}
