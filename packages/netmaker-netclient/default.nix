{ lib
, fetchFromGitHub
, buildGo118Module
, makeWrapper
, wireguard-tools
, sysctl
, nftables
, iproute2
}:

let
  version = "0.16.1";
in
buildGo118Module {
  pname = "netclient";
  version = version;
  src = fetchFromGitHub {
    owner = "gravitl";
    repo = "netmaker";
    rev = "v${version}";
    sha256 = "sha256-asAL+oldTPq1xt8/wA7xEQ1eGr/J0sejJw7Q7VO5G+g=";
  };
  ldflags = [
    "-X"
    "main.version=v${version}"
  ];
  nativeBuildInputs = [ makeWrapper ];
  postInstall =
    let
      binPath = lib.strings.makeBinPath [ wireguard-tools sysctl nftables iproute2 ];
    in
    ''
      wrapProgram $out/bin/netclient --prefix PATH : "${binPath}"
    '';
  subPackages = [ "netclient" ];
  vendorSha256 = "sha256-eHlXSffng73bwLeWAqDN2yY1EZV4iLo1v4xL031TLdI=";
}
