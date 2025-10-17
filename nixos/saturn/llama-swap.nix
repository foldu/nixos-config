{ ... }:
let
  swapPort = 9292;
in
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
          "${toString swapPort}:8080"
        ];
        autoUpdate = "registry";
      };
    };
  };

  services.caddy.extraConfig = ''
    llama.home.5kw.li {
      reverse_proxy localhost:${toString swapPort}
    }
  '';
}
