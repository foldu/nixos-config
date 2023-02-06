{ pkgs, ... }:
let
  privateKey = "/var/secrets/peerix-private";
in
{
  # users.users.peerix = {
  #   isSystemUser = true;
  #   group = "peerix";
  #   extraGroups = [ "secrets" ];
  # };
  #
  # users.groups.peerix = { };
  #
  # systemd.tmpfiles.rules = [
  #   "z ${privateKey} 600 peerix secrets"
  # ];
  #
  # services.peerix = {
  #   enable = true;
  #   user = "peerix";
  #   group = "peerix";
  #   privateKeyFile = privateKey;
  #   publicKeys = [
  #     "peerix-mars:jPOXX3+AykMdjmAabOPlkm3Mh54ETKV38caHNaTmt3E="
  #     "peerix-saturn:CuK1LG2ACIXAhCxG1e1V3p6wXcebOUltcI9Wo6MIvFg="
  #     "peerix-jupiter:XkzYiGV5m7D4t8jKQJxmF0FGp9igpSSvfxBRi2a4HbI="
  #     "peerix-ceres:Xx1DvgjuKT+W6MQD5RjbgS7Z3W0ABrbW0AtPXgX7Jq0="
  #   ];
  #   openFirewall = true;
  #   extraArguments = "--timeout 500";
  # };
}
