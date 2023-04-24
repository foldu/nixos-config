{ pkgs, inputs, configSettings, ... }: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [ "de_DE.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" ];
  };

  time.timeZone = "Europe/Amsterdam";

  environment.sessionVariables = {
    EDITOR = "nvim";
    LESS = "-gciMRwX";
    NIX_GCC = "${pkgs.gcc}/bin/gcc";
    NIX_SQLITE = "${pkgs.sqlite.out}/lib/libsqlite3.so";
    MANPAGER = "nvim +Man!";
  };

  # this is set to false in the default config for reasons I forgot so do it here too
  networking.useDHCP = false;

  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
    settings.auto-optimise-store = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      X11Forwarding = false;
    };
  };

  security.sudo.enable = true;

  #users.mutableUsers = false;
  users.users.barnabas = {
    isNormalUser = true;
    uid = 1000;
    shell = pkgs.nushell;
    extraGroups = [ "wheel" "video" "audio" "dialout" "networkmanager" ];
  };

  # why is this false by default?
  systemd.coredump.enable = true;

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  home-manager = {
    extraSpecialArgs = { inherit inputs configSettings; };
    useGlobalPkgs = true;
  };

  home-manager.users.barnabas.home.stateVersion = "18.09";

  boot.tmp.useTmpfs = true;

  networking.firewall.enable = true;

  # increase fd limits because they're way too low
  security.pam.loginLimits = [
    { domain = "*"; item = "nofile"; type = "soft"; value = "65536"; }
    { domain = "*"; item = "nofile"; type = "hard"; value = "65536"; }
  ];

  # disable nixos containers(doesn't work on older stateversions with podman containers)
  boot.enableContainers = false;
}
