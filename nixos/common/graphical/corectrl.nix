{ ... }:
{
  programs.corectrl = {
    enable = true;
    gpuOverclock = {
      enable = true;
      ppfeaturemask = "0xffffffff";
    };
  };

  users.users.barnabas.extraGroups = [ "corectrl" ];
}
