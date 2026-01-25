{ inputs, ... }:
{
  imports = [
    inputs.quadlet-nix.nixosModules.quadlet
  ];

  virtualisation.quadlet.containers.llama-cpp = {
    containerConfig = {
      environments.LLAMA_CACHE = "/llama-cache";
      exec = [
        # "llama-server"
        "--models-preset"
        "/llama-config.ini"
        "--models-max"
        "1"
        "-sm"
        "none"
        "-mg"
        "0"
      ];
      devices = [
        "/dev/dri"
        "/dev/kfd"
      ];
      image = "ghcr.io/ggml-org/llama.cpp:server-rocm";
      volumes = [
        # "/srv/media/fast/ai/llm/models:/models"
        # "/srv/media/fast/ai/llm/llama-swap-config.yaml:/app/config.yaml"
        "/var/lib/llama-cpp/models:/llama-cache"
        "/var/lib/llama-cpp/llama-config.ini:/llama-config.ini"
      ];
      publishPorts = [
        "9292:8080"
      ];
      autoUpdate = "registry";
    };
  };
}
