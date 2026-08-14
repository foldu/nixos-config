{ ... }:
{
  imports = [ ../generic ];

  services.telegraf.extraConfig.global_tags.type = "server";
}
