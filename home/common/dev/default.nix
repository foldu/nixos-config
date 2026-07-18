{
  inputs,
  pkgs,
  ...
}:
let
  postgresDir = "/home/barnabas/.local/share/postgresql";
in
{
  imports = [
    ./rust.nix
    inputs.quadlet-nix.homeManagerModules.quadlet
  ];

  systemd.user.sessionVariables = {
    EDITOR = "nvim";
  };

  systemd.user.tmpfiles.rules = [
    "d ${postgresDir} 755 barnabas users"
  ];

  services.podman = {
    enable = true;
    autoUpdate.enable = true;
  };

  # virtualisation.quadlet.containers.postgres-dev = {
  #   autoStart = true;
  #   containerConfig = {
  #     image = "docker.io/postgres:17";
  #     volumes = [
  #       "${postgresDir}:/var/lib/postgresql/data"
  #     ];
  #     environments = {
  #       POSTGRES_PASSWORD = "changeme";
  #     };
  #     publishPorts = [
  #       "127.0.0.1:5432:5432"
  #     ];
  #     autoUpdate = "registry";
  #     userns = "keep-id";
  #   };
  # };
  xdg.configFile = {
    "pnpm/config.yaml".text = ''
      # 2 days
      minimumReleaseAge: 2880
    '';
  };

  home.packages =
    let
      llm-agents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
    in
    with pkgs;
    [
      # editors
      zed-editor
      # tools
      gnumake
      glab
      tokei
      devenv

      # editor tools
      ast-grep
      tree-sitter

      # c/c++ native tools
      clang-tools
      llvmPackages_latest.lld
      llvmPackages_latest.clang
      cmake
      neocmakelsp
      cmake-lint
      cmake-format

      bubblewrap

      llm-agents.reasonix
      llm-agents.opencode

      # sql
      # sqlfluff
      sqlite-interactive

      # go
      go
      gopls

      # typst
      typst
      tinymist
      typstyle
      typst-live

      # tex
      texlab

      # nix
      nixd
      nixfmt

      # shell
      shellcheck
      shfmt

      # webshit
      nodejs
      pnpm

      # lua
      stylua

      # markdown
      marksman
      markdownlint-cli2

      # :goat
      zig

      # :snek
      python314
      uv
      ruff
    ];
}
