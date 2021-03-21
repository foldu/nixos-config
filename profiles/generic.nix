{ pkgs, lib, config, inputs, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "Europe/Amsterdam";

  environment.sessionVariables = {
    EDITOR = "vi";
    LESS = "-gciMRwX";
  };

  # this is set to false in the default config for reasons I forgot so do it here too
  networking.useDHCP = false;

  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
    autoOptimiseStore = true;
  };

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    forwardX11 = false;
    permitRootLogin = "no";
  };

  security.sudo.enable = false;
  security.doas = {
    enable = true;
    extraRules = [{
      users = [ "barnabas" ];
      keepEnv = true;
      persist = true;
    }];
  };

  # TODO: figure out git crypt first
  #users.mutableUsers = false;
  users.users.barnabas = {
    isNormalUser = true;
    uid = 1000;
    shell = pkgs.fish;
    extraGroups = [ "wheel" "video" "audio" "dialout" "networkmanager" ];
  };

  # why is this false by default?
  systemd.coredump.enable = true;

  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  home-manager.useGlobalPkgs = true;

  boot.tmpOnTmpfs = true;

  networking.firewall.enable = true;

  # increase fd limits because they're way too low
  security.pam.loginLimits = [
    { domain = "*"; item = "nofile"; type = "soft"; value = "65536"; }
    { domain = "*"; item = "nofile"; type = "hard"; value = "65536"; }
  ];
}
