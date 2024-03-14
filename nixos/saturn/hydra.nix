{ config, ... }:
{
  services.hydra = {
    enable = false;
    hydraURL = "https://hydra.home.5kw.li"; # externally visible URL
    notificationSender = "hydra@localhost"; # e-mail of hydra service
    # a standalone hydra will require you to unset the buildMachinesFiles list to avoid using a nonexistant /etc/nix/machines
    buildMachinesFiles = [ ];
    # you will probably also want, otherwise *everything* will be built from scratch
    useSubstitutes = true;
    port = 3339;
  };

  services.caddy.extraConfig = ''
    hydra.home.5kw.li {
      reverse_proxy http://127.0.0.1:${toString config.services.hydra.port}
    }
  '';
}
