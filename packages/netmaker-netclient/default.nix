{ lib
, fetchFromGitHub
, buildGo118Module
, makeWrapper
, wireguard-tools
, sysctl
}:

let
  version = "0.14.5";
in
buildGo118Module {
  pname = "netclient";
  version = version;
  src = fetchFromGitHub {
    owner = "gravitl";
    repo = "netmaker";
    rev = "v${version}";
    sha256 = "sha256-0OQJhHPGSWrY4eOpWI6cLOY4xokGnQKMfiYxm1kxiI0=";
  };
  ldflags = [
    "-X"
    "main.version=v${version}"
  ];
  nativeBuildInputs = [ makeWrapper ];
  postInstall =
    let
      binPath = lib.strings.makeBinPath [ wireguard-tools sysctl ];
    in
    ''
      wrapProgram $out/bin/netclient --prefix PATH : "${binPath}"
    '';
  subPackages = [ "netclient" ];
  vendorSha256 = "sha256-9HxM2gh5btk+cGUnTn+b9HzmrGDZVkPGB0ekMLaKPjc=";
}
