{ pkgs, inputs, ... }:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  environment.systemPackages = with pkgs; [
    age
    sops
  ];

  sops.defaultSopsFile = ../../../secrets/secrets.yaml;
  sops.age.keyFile = "/home/barnabas/.config/sops/age/keys.txt";

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
}
