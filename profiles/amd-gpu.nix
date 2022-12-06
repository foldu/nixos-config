{ config, lib, pkgs, ... }:

{
  hardware.opengl.extraPackages = with pkgs; [
    #rocm-opencl-icd
  ];

  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;
}
