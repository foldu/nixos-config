{ pkgs, ... }:
{
  virtualisation.libvirtd = {
    qemu.vhostUserPackages = with pkgs; [ virtiofsd ];
    enable = true;
  };
  programs.virt-manager.enable = true;
  users.users.barnabas.extraGroups = [ "libvirtd" ];
  environment.systemPackages = [ pkgs.gnome-boxes ];
}
