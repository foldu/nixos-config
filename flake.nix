{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pickwp = {
      type = "gitlab";
      owner = "foldu";
      repo = "pickwp";
      ref = "master";
      host = "lab.home.5kw.li";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
    };

    atchr = {
      type = "gitlab";
      owner = "foldu";
      repo = "atchr";
      ref = "master";
      host = "lab.home.5kw.li";
    };

    homeserver-sekret = {
      type = "git";
      url = "https://lab.home.5kw.li/foldu/sekret";
      flake = false;
    };

    wpp-gtk = {
      type = "git";
      url = "https://lab.home.5kw.li/foldu/wpp-gtk";
    };

    kanagawa-theme = {
      url = "github:rebelot/kanagawa.nvim";
      flake = false;
    };

    eunzip.url = "github:foldu/eunzip";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    quadlet-nix = {
      url = "github:SEIAROTg/quadlet-nix";
    };

    cashewnix.url = "github:foldu/cashewnix";

    copyparty.url = "github:9001/copyparty";

    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell/";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel";

    llm-agents.url = "github:numtide/llm-agents.nix";

    nix-topology = {
      url = "github:oddlama/nix-topology";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      cashewnix,
      flake-utils,
      sops-nix,
      nix-topology,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      home-network = fromTOML (builtins.readFile ./home-network.toml);
      getSettings = import ./settings.nix;
      mkHome =
        modules: pkgs:
        home-manager.lib.homeManagerConfiguration {
          inherit modules pkgs;
          extraSpecialArgs = {
            inherit
              inputs
              outputs
              home-network
              getSettings
              ;
          };
        };
      mkNixos =
        system: modules:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = modules ++ [
            sops-nix.nixosModules.sops
            cashewnix.nixosModules.cashewnix
            nix-topology.nixosModules.default
            ./docs/topology-extractors.nix
          ];
          specialArgs = {
            inherit
              inputs
              outputs
              home-network
              getSettings
              ;
          };
        };
    in
    {
      homeConfigurations = {
        "barnabas@jupiter" = mkHome [ ./home/jupiter ] nixpkgs.legacyPackages."x86_64-linux";
        "barnabas@saturn" = mkHome [ ./home/saturn ] nixpkgs.legacyPackages."x86_64-linux";
        "barnabas@venus" = mkHome [ ./home/venus ] nixpkgs.legacyPackages."x86_64-linux";
      };
      nixosConfigurations = {
        "jupiter" = mkNixos "x86_64-linux" [ ./nixos/jupiter ];
        "saturn" = mkNixos "x86_64-linux" [ ./nixos/saturn ];
        "venus" = mkNixos "x86_64-linux" [ ./nixos/venus ];
        "ubuntu-4gb-fsn1-3" = mkNixos "aarch64-linux" [ ./nixos/ubuntu-4gb-fsn1-3 ];
      };
      overlays = import ./overlays { inherit inputs; };
      lib = import ./lib { inherit (nixpkgs) lib; };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = {
          helium = pkgs.callPackage ./packages/helium { };
          hassctl = pkgs.callPackage ./packages/hassctl { };
        };

        topology = import nix-topology {
          # the topology overlay provides the renderer tooling (elk-to-svg)
          pkgs = nixpkgs.legacyPackages.${system}.extend nix-topology.overlays.default;
          modules = [
            ./docs/topology.nix
            {
              inherit (self) nixosConfigurations;
            }
          ];
        };
      }
    );
}
