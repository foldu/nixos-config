{ ... }:
{
  hardware.amdgpu.overdrive = {
    enable = true;
    ppfeaturemask = "0xffffffff";
  };
  programs.corectrl.enable = true;

  users.users.barnabas.extraGroups = [ "corectrl" ];
}
