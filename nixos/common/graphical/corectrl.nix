{ ... }:
{
  programs.corectrl = {
    enable = true;
    gpuOverclock.enable = true;
  };

  users.users.barnabas.extraGroups = [ "corectrl" ];
}
