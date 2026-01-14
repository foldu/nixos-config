{ pkgs, inputs, ... }:
let
  postgresDir = "/home/barnabas/.local/share/postgresql";
in
{
  imports = [
    ./rust.nix
    inputs.quadlet-nix.homeManagerModules.quadlet
    ./powershell
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

  home.packages = with pkgs; [
    # editors
    zed-editor
    # tools
    gnumake
    glab
    tokei

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

    # sql
    # sqlfluff
    sqlite-interactive

    # go
    go

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
    nodePackages.prettier
    deno

    # lua
    stylua

    # markdown
    marksman
    markdownlint-cli2

    # java
    jdk21
    maven
    gradle

    dotnet-sdk_10

    # :goat
    zig

    # :snek
    python314
    uv
    ruff
  ];
}
