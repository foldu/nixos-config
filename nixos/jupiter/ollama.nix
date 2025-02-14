{ inputs, ... }:
{
  imports = [
    inputs.quadlet-nix.nixosModules.quadlet
  ];

  virtualisation.quadlet = {
    containers.ollama = {
      containerConfig = {
        image = "docker.io/ollama/ollama:rocm";
        devices = [
          "/dev/dri"
          "/dev/kfd"
        ];
        volumes = [
          "/home/barnabas/ai/text/ollama:/root/.ollama"
          "/home/barnabas/ai/text/models:/root/models"
        ];
        publishPorts = [
          "11434:11434"
        ];
        autoUpdate = "registry";
        environments = {
          OLLAMA_FLASH_ATTENTION = "1";
          OLLAMA_KV_CACHE_TYPE = "q8_0";
          OLLAMA_MAX_LOADED_MODELS = "1";
        };
      };
    };
  };
}
