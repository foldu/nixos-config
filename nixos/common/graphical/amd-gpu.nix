{ ... }:
{
  hardware.amdgpu = {
    overdrive.enable = true;
    opencl.enable = true;
  };

  services.lact.enable = true;
}
