{ pkgs, config, ... }: {
  hardware.cpu.intel.updateMicrocode = true;
  hardware.cpu.amd.updateMicrocode = true;
}
