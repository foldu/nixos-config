{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    stable.url = "github:NixOS/nixpkgs/nixos-20.09";

    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:rycee/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    naersk = {
      url = "github:nmattia/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pickwp = {
      type = "git";
      url = "https://git-home.5kw.li/foldu/pickwp";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.naersk.follows = "naersk";
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
    };

    doom-emacs = {
      url = "github:hlissner/doom-emacs";
      flake = false;
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wrrr = {
      type = "git";
      url = "https://git-home.5kw.li/foldu/wrrr";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.naersk.follows = "naersk";
    };

    huh = {
      url = "github:foldu/huh";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.naersk.follows = "naersk";
      inputs.flake-utils.follows = "flake-utils";
    };

    eunzip = {
      url = "github:foldu/eunzip";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.naersk.follows = "naersk";
      inputs.flake-utils.follows = "flake-utils";
    };

    blocklistdownloadthing = {
      url = "github:foldu/blocklistdownloadthing";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.naersk.follows = "naersk";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs =
    { self
    , nixpkgs
    , emacs-overlay
    , rust-overlay
    , nixos-hardware
    , pickwp
    , wrrr
    , huh
    , flake-utils
    , home-manager
    , naersk
    , doom-emacs
    , stable
    , blocklistdownloadthing
    , eunzip
    }@inputs:
    let
      home-network = fromTOML (builtins.readFile ./home-network.toml);
      mkPkgs = inputPkgs: system: (import inputPkgs {
        inherit system;
        overlays = [
          emacs-overlay.overlay
          rust-overlay.overlay
          pickwp.overlay
          eunzip.overlay
          wrrr.overlay
          huh.overlay
          blocklistdownloadthing.overlay
          (import ./overlays)
        ];
        config.allowUnfree = true;
      });
      mkHost = { system, hostName, modules, pkgs }:
        let
          hostPkgs = mkPkgs pkgs system;
          configSettings = import ./settings.nix {
            pkgs = hostPkgs;
          };
        in
        nixpkgs.lib.nixosSystem
          {
            inherit system;
            pkgs = hostPkgs;
            specialArgs = { inherit inputs home-network configSettings; };
            modules = [
              ({ pkgs, ... }: {
                networking.hostName = hostName;
                # Let 'nixos-version --json' know about the Git revision
                # of this flake.
                system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
                nix.registry = {
                  nixpkgs.flake = nixpkgs;
                };
                environment.systemPackages = with pkgs; [
                  git
                  git-crypt
                ];
              })
            ] ++ modules;
          };

      mkHosts = nixpkgs.lib.attrsets.mapAttrs
        (name: value: mkHost (nixpkgs.lib.recursiveUpdate { hostName = name; } value));
    in
    {
      nixosConfigurations = mkHosts {
        mars = {
          system = "x86_64-linux";
          pkgs = inputs.nixpkgs;
          modules = [
            nixos-hardware.nixosModules.lenovo-thinkpad-t14-amd-gen1
            nixos-hardware.nixosModules.common-pc-laptop-ssd
            ./hosts/mars/configuration.nix
          ];
        };

        jupiter = {
          system = "x86_64-linux";
          pkgs = inputs.nixpkgs;
          modules = [
            nixos-hardware.nixosModules.common-pc-ssd
            ./hosts/jupiter/configuration.nix
          ];
        };

        ceres = {
          system = "aarch64-linux";
          pkgs = inputs.nixpkgs;
          modules = [
            ./hosts/ceres/configuration.nix
          ];
        };
      };
    };
}
