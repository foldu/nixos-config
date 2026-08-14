{ config, ... }:
{
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;
  hardware.nvidia-container-toolkit.enable = true;

  services.telegraf.extraConfig.inputs.nvidia_smi = {
    bin_path = "${config.hardware.nvidia.package.bin}/bin/nvidia-smi";
  };
}
