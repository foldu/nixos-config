{ lib
, fetchFromGitHub
, buildGo118Module
, makeWrapper
, wireguard-tools
, sysctl
}:

let
  version = "0.14.6";
in
buildGo118Module {
  pname = "netclient";
  version = version;
  src = fetchFromGitHub {
    owner = "gravitl";
    repo = "netmaker";
    rev = "v${version}";
    sha256 = "sha256-rLIrc8Jm89dEyH/UJzXaHU59tegfQhMGc1E0SWMSPUU=";
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
  vendorSha256 = "sha256-AfD5d0KDnVIEo4glf1IqTT33XvXbnMILhCbyslUdZiQ=";
}
