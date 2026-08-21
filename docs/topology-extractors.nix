{ config, lib, ... }:
{
  topology.self.services.gitlab-runner = lib.mkIf config.services.gitlab-runner.enable {
    name = "GitLab Runner";
    icon = ./img/gitlab.svg;
    info = "gitlab runner (${toString config.services.gitlab-runner.settings.concurrent} concurrent)";
    details.runners.text = lib.concatStringsSep ", " (
      lib.attrNames config.services.gitlab-runner.services
    );
  };

  topology.self.services.netbird-server = lib.mkIf (
    config.virtualisation.quadlet.containers ? netbird-server
  ) {
    name = "Netbird Server";
    icon = ./img/netbird.svg;
  };
}
