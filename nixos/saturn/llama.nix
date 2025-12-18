{ ... }:
let
  swapPort = 9292;
in
{
  virtualisation.quadlet = {
    containers.llama-cpp = {
      containerConfig = {
        environments.LLAMA_CACHE = "/llama-cache";
        exec = [
          # "llama-server"
          "--models-preset"
          "/llama-config.ini"
          "--models-max"
          "1"
        ];
        image = "ghcr.io/ggml-org/llama.cpp:server-cuda";
        devices = [
          "nvidia.com/gpu=all"
        ];
        volumes = [
          # "/srv/media/fast/ai/llm/models:/models"
          # "/srv/media/fast/ai/llm/llama-swap-config.yaml:/app/config.yaml"
          "/srv/media/fast/ai/llm/llama-cache:/llama-cache"
          "/srv/media/fast/ai/llm/llama-config.ini:/llama-config.ini"
        ];
        publishPorts = [
          "${toString swapPort}:8080"
        ];
        autoUpdate = "registry";
      };
    };
  };

  services.caddy.virtualHosts."llama.home.5kw.li".extraConfig = ''
    @valid_auth_header {
      header Auhorization {env.LLAMA_SWAP_API_KEY}
    }

    handle @valid_auth_header {
      reverse_proxy :${toString swapPort}
    }

    handle {
      forward_auth https://auth.home.5kw.li {
        uri /api/authz/forward-auth
        copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
        header_up Host {upstream_hostport}
      }
      reverse_proxy :${toString swapPort}
    }
  '';
}
