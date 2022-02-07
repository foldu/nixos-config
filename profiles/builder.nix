{ pkgs, ... }: {
  users.users.nixosbuilder = {
    name = "nixosbuilder";
    shell = pkgs.bash;
    isSystemUser = true;
    group = "nixosbuilder";
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGeVYFct3i/m/OVpsztczbTT1pAaOcRMBXVuRuXJLMbs" ];
  };

  users.groups.nixosbuilder = { };

  nix.settings.trusted-users = [
    "root"
    "nixosbuilder"
  ];

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
