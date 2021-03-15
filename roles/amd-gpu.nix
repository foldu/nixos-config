{ config, lib, pkgs, ... }:

{
  hardware.opengl.extraPackages = with pkgs; [
    rocm-opencl-icd
    amdvlk
  ];

  environment.variables.VK_ICD_FILENAMES =
    "/run/opengl-driver/share/vulkan/icd.d/amd_icd64.json";

  hardware.opengl.driSupport = true;
}
