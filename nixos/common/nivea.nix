{ config, ... }:
{
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;
  # don't install nvidia-settings (GUI tool, useless on a headless server)
  hardware.nvidia.nvidiaSettings = false;
  hardware.nvidia-container-toolkit.enable = true;

  services.telegraf.extraConfig.inputs.nvidia_smi = {
    bin_path = "${config.hardware.nvidia.package.bin}/bin/nvidia-smi";
  };
}
