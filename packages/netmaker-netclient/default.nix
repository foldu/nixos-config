{ lib
, fetchFromGitHub
, buildGo118Module
, makeWrapper
, wireguard-tools
, sysctl
, iptables
, iproute2
}:

let
  version = "0.16.0";
in
buildGo118Module {
  pname = "netclient";
  version = version;
  src = fetchFromGitHub {
    owner = "gravitl";
    repo = "netmaker";
    rev = "v${version}";
    sha256 = "sha256-kXFPXEVZyLMtzkJz1i2iA0XXICaet0X8f9B9MF3en+4=";
  };
  ldflags = [
    "-X"
    "main.version=v${version}"
  ];
  nativeBuildInputs = [ makeWrapper ];
  postInstall =
    let
      binPath = lib.strings.makeBinPath [ wireguard-tools sysctl iptables ];
    in
    ''
      wrapProgram $out/bin/netclient --prefix PATH : "${binPath}"
    '';
  subPackages = [ "netclient" ];
  vendorSha256 = "sha256-3FO5UWFVZnux9zxdAKyvAgxXi6M3uL6oehhJUvrztiI=";
}
