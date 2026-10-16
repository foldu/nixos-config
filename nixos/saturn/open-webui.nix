{ ... }:
let
  port = 8080;
  domain = "ai.home.5kw.li";
in
{
  virtualisation.quadlet.containers.open-webui = {
    containerConfig = {
      image = "ghcr.io/open-webui/open-webui:v0.11.4";

      environments = {
        # Authelia (Caddy forward_auth below) is the only way in, so Open WebUI
        # keeps no accounts of its own and never prompts a second time. Set
        # WEBUI_AUTH to true (plus WEBUI_AUTH_TRUSTED_EMAIL_HEADER=Remote-Email)
        # to give every authelia user their own chats instead.
        WEBUI_AUTH = "false";
        WEBUI_URL = "https://${domain}";

        # llama.cpp serves the OpenAI API; quadlet puts it on the default podman
        # network as `llama-cpp`, where this container resolves it by name.
        OPENAI_API_BASE_URL = "http://llama-cpp:8080/v1";
        OPENAI_API_KEY = "none";
        ENABLE_OLLAMA_API = "false";
      };

      volumes = [
        "/var/lib/open-webui:/app/backend/data"
      ];
      publishPorts = [
        "127.0.0.1:${toString port}:8080"
      ];
      autoUpdate = "registry";
    };
  };

  services.caddy.virtualHosts.${domain}.extraConfig = ''
    forward_auth https://auth.home.5kw.li {
      uri /api/authz/forward-auth
      copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
      header_up Host {upstream_hostport}
    }
    reverse_proxy localhost:${toString port}
  '';
}
