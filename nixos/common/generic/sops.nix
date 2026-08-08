{ pkgs, inputs, ... }:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  environment.systemPackages = with pkgs; [
    age
    sops
    ssh-to-age
  ];

  # Per-host identity = the ssh host key (see the server_* recipients in
  # .sops.yaml). The admin key (admin_barnabas) is the backed-up recovery,
  # if the host key breaks, use it to add the new one in .sops.yaml and `sops updatekeys`
  # admin key is in bitwarden vault
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
}
