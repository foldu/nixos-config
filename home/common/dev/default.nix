{ pkgs, inputs, ... }:
let
  postgresDir = "/home/barnabas/.local/share/postgresql";
in
{
  imports = [
    ./rust.nix
    ./python.nix
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

  virtualisation.quadlet.containers.postgres-dev = {
    autoStart = true;
    containerConfig = {
      image = "docker.io/postgres:17";
      volumes = [
        "${postgresDir}:/var/lib/postgresql/data"
      ];
      environments = {
        POSTGRES_PASSWORD = "changeme";
      };
      publishPorts = [
        "127.0.0.1:5432:5432"
      ];
      autoUpdate = "registry";
      userns = "keep-id";
    };
  };

  home.packages = with pkgs; [
    # editors
    # zed-editor
    tokei
    gdb
    # tools
    yarn
    gnumake
    just
    cookiecutter
    plantuml
    glab

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
    sqlfluff
    sqlite-interactive

    # go
    go
    gopls

    # typst
    typst
    typst-fmt
    tinymist
    typstyle
    typst-live

    # tex
    texlab

    # nix
    nixd
    nixfmt-rfc-style

    # shell
    nodePackages.bash-language-server
    shellcheck
    shfmt

    # webshit
    nodePackages.prettier
    nodePackages.typescript
    nodePackages.typescript-language-server
    nodePackages.eslint
    nodePackages.vscode-langservers-extracted
    vue-language-server
    tailwindcss-language-server
    nodejs
    bun
    vtsls

    # yaml
    nodePackages.yaml-language-server
    taplo-cli
    # lua
    stylua
    sumneko-lua-language-server

    # markdown
    marksman
    markdownlint-cli2

    # java
    jdt-language-server
    jdk21
    maven

    # :goat
    zig
    zls
  ];
}
