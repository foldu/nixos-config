{ inputs, ... }:
let
  openwebui-port = 7742;
  openwebui-data = "/var/lib/openwebui";
in
{
  imports = [
    inputs.quadlet-nix.nixosModules.quadlet
  ];

  systemd.tmpfiles.rules = [
    "d ${openwebui-data} 700 root root"
  ];

  virtualisation.quadlet.containers.open-webui = {
    containerConfig = {
      image = "ghcr.io/open-webui/open-webui:main";
      volumes = [
        "${openwebui-data}:/app/backend/data"
      ];
      publishPorts = [
        "${toString openwebui-port}:8080"
      ];
      autoUpdate = "registry";
      environments = {
        WEBUI_URL = "https://ai.home.5kw.li";
      };
    };
  };

  services.caddy.extraConfig = ''
    ai.home.5kw.li {
      reverse_proxy localhost:${toString openwebui-port}
    }
  '';
}
