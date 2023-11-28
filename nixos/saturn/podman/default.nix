{ pkgs, inputs, config, ... }: {
  virtualisation.podman = {
    enable = true;
    extraPackages = [ pkgs.netavark ];
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  virtualisation.oci-containers.backend = "podman";

  # doesn't werk for some reason
  systemd.timers.podman-auto-update = {
    enable = false;
    # timerConfig.OnCalendar = "03:00";
    # wantedBy = [ "timers.target" ];
  };

  systemd.services.my-podman-auto-update = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = inputs.nix-stuff.packages.${pkgs.system}.writeNuScript {
        name = "my-podman-auto-update";
        file = ./podman-auto-update.nu;
        path = [ config.virtualisation.podman.package ];
      };
    };
  };

  systemd.timers.my-podman-auto-update = {
    enable = true;
    timerConfig.OnCalendar = "03:00";
    wantedBy = [ "timers.target" ];
  };
}
