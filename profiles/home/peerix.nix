{ pkgs, ... }:
let
  privateKey = "/var/secrets/peerix-private";
in
{
  users.users.peerix = {
    isSystemUser = true;
    group = "peerix";
    extraGroups = [ "secrets" ];
  };

  users.groups.peerix = { };

  systemd.tmpfiles.rules = [
    "z ${privateKey} 600 peerix nobody"
  ];

  services.peerix = {
    enable = true;
    privateKeyFile = privateKey;
    publicKey = "peerix-mars:jPOXX3+AykMdjmAabOPlkm3Mh54ETKV38caHNaTmt3E= peerix-saturn:CuK1LG2ACIXAhCxG1e1V3p6wXcebOUltcI9Wo6MIvFg=";
    openFirewall = true;
    extraArguments = "--timeout 500";
  };
}
