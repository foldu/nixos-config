{ outputs, ... }: {
  home.stateVersion = "22.11";
  systemd.user.startServices = "sd-switch";

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);
    };
  };

  home = {
    username = "barnabas";
    homeDirectory = "/home/barnabas";
  };

  programs.home-manager.enable = true;
}
