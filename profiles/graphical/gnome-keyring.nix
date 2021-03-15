{ config, lib, pkgs, ... }:
let
  uid = config.users.users.barnabas.uid;
in
{
  # DO NOT TOUCH THIS
  # I REPEAT NO TOUCHY
  services.dbus.packages = [ pkgs.gcr ];
  services.gnome3.gnome-keyring.enable = true;
  security.pam.services.gdm.enableGnomeKeyring = true;
  programs.seahorse.enable = true;

  home-manager.users.barnabas = { ... }: {
    systemd.user.sessionVariables.SSH_AUTH_SOCK = "/run/user/${toString uid}/keyring/ssh";
    services.gnome-keyring.enable = true;
    services.gpg-agent = {
      enable = true;
      pinentryFlavor = "gnome3";
    };
  };
}
