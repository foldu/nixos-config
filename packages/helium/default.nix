# stolen from https://github.com/FKouhai/helium2nix/blob/main/flake.nix
{
  commandLineArgs ? [ ],
  enableFeatures ? [ ],
  libvaSupport ? true,
  lib,
  appimageTools,
  fetchurl,
  makeWrapper,
}:
appimageTools.wrapType2 rec {

  pname = "helium";
  version = "0.9.4.1";

  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/${pname}-${version}-x86_64.AppImage";
    sha256 = "sha256-N5gdWuxOrIudJx/4nYo4/SKSxakpTFvL4zzByv6Cnug=";
  };

  _enableFeatures =
    enableFeatures
    ++ lib.optionals libvaSupport [
      "VaapiVideoDecoder"
    ];

  extraPkgs = pkgs: pkgs.lib.optionals libvaSupport [ pkgs.libva ];

  extraBwrapArgs = [
    "--ro-bind-try /etc/chromium /etc/chromium"
  ];

  nativeBuildInputs = [ makeWrapper ];

  extraInstallCommands =
    let
      contents = appimageTools.extract { inherit pname version src; };
    in
    ''
      wrapProgram $out/bin/${pname} \
        ${
          lib.optionalString (
            _enableFeatures != [ ]
          ) "--add-flags \"--enable-features=${lib.strings.concatStringsSep "," _enableFeatures}\""
        } \
        ${lib.optionalString (
          commandLineArgs != [ ]
        ) "--add-flags \"${lib.strings.concatStringsSep " " commandLineArgs}\""}
      install -m 444 -D ${contents}/${pname}.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace 'Exec=AppRun' 'Exec=${pname}'
      cp -r ${contents}/usr/share/icons $out/share
    '';

}
