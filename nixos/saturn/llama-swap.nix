{ ... }:
{
  virtualisation.quadlet = {
    containers.llama-swap = {
      containerConfig = {
        image = "ghcr.io/mostlygeek/llama-swap:cuda";
        devices = [
          "nvidia.com/gpu=all"
        ];
        volumes = [
          "/srv/media/fast/ai/llm/models:/models"
          "/srv/media/fast/ai/llm/llama-swap-config.yaml:/app/config.yaml"
          "/srv/media/fast/ai/llm/llama-cache:/root/.cache/llama.cpp"
        ];
        publishPorts = [
          "9292:8080"
        ];
        autoUpdate = "registry";
      };
    };
  };
}
