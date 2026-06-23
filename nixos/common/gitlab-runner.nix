{
  lib,
  config,
  pkgs,
  ...
}:
{
  boot.kernel.sysctl."net.ipv4.ip_forward" = true;

  sops.secrets."gitlab-runner/default" = { };
  sops.secrets."gitlab-runner/buildkit" = { };
  sops.secrets."gitlab-runner/nix" = { };

  # podman docker compat mode just causes too many problems, use normal docker instead
  virtualisation.docker = {
    enable = true;
  };

  services.gitlab-runner =
    let
      # for some reason saturn can't access anything from netbird or the local network
      # so just hack in host networking
      saturnFix =
        if (config.networking.hostName == "saturn") then
          [
            "--docker-network-mode host"
          ]
        else
          [ ];
    in
    {
      enable = true;
      clear-docker-cache = {
        enable = true;
        flags = [ "prune" ];
        dates = "weekly";
      };
      settings = {
        concurrent = 6;
        feature_flags = {
          FF_ENABLE_JOB_CLEANUP = true;
          FF_USE_ADAPTIVE_REQUEST_CONCURRENCY = true;
        };
      };
      services = {
        # runner for building in docker via host's nix-daemon
        # nix store will be readable in runner, might be insecure
        nix = with lib; {
          # File should contain at least these two variables:
          # `CI_SERVER_URL`
          # `CI_SERVER_TOKEN`
          authenticationTokenConfigFile = config.sops.secrets."gitlab-runner/nix".path;
          dockerImage = "docker.io/alpine";
          dockerVolumes = [
            "/nix/store:/nix/store:ro"
            "/nix/var/nix/db:/nix/var/nix/db:ro"
            "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro"
            "/etc/nix/nix.conf:/etc/nix/nix.conf:ro"
            "/etc/ssl/certs:/etc/ssl/certs:ro"
            "/etc/static/ssl/certs:/etc/static/ssl/certs:ro"
          ];
          dockerDisableCache = false;
          dockerPrivileged = true;
          preBuildScript = pkgs.writeScript "setup-container" ''
            mkdir -p -m 0755 /nix/var/log/nix/drvs
            mkdir -p -m 0755 /nix/var/nix/gcroots
            mkdir -p -m 0755 /nix/var/nix/profiles
            mkdir -p -m 0755 /nix/var/nix/temproots
            mkdir -p -m 0755 /nix/var/nix/userpool
            mkdir -p -m 1777 /nix/var/nix/gcroots/per-user
            mkdir -p -m 1777 /nix/var/nix/profiles/per-user
            mkdir -p -m 0755 /nix/var/nix/profiles/per-user/root
            mkdir -p -m 0700 "$HOME/.nix-defexpr"

            . ${pkgs.lix}/etc/profile.d/nix.sh

            ${pkgs.lix}/bin/nix-env -i ${
              concatStringsSep " " (
                with pkgs;
                [
                  lix
                  git
                  openssh
                ]
              )
            }
          '';
          environmentVariables = {
            ENV = "/etc/profile";
            USER = "root";
            NIX_REMOTE = "daemon";
            PATH = "/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin";
          };
          requestConcurrency = 4;
          registrationFlags = [ ] ++ saturnFix;
        };

        default = {
          authenticationTokenConfigFile = config.sops.secrets."gitlab-runner/default".path;
          dockerImage = "docker.io/ubuntu:latest";
          dockerPrivileged = false;
          dockerDisableCache = false;
          requestConcurrency = 4;
          registrationFlags = [ ] ++ saturnFix;
        };

        buildkit =
          let
            dockerImage = "docker.io/moby/buildkit:rootless";
          in
          {
            authenticationTokenConfigFile = config.sops.secrets."gitlab-runner/buildkit".path;
            inherit dockerImage;
            dockerAllowedImages = [ dockerImage ];
            dockerPullPolicy = "always";
            dockerPrivileged = false;
            dockerDisableCache = false;
            requestConcurrency = 4;
            registrationFlags = [
              "--docker-security-opt seccomp=unconfined"
              "--docker-security-opt apparmor=unconfined"
            ]
            ++ saturnFix;
          };
      };
    };
}
