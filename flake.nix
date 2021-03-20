{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

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
    , blocklistdownloadthing
    , eunzip
    }@inputs:
    # NOTE: don't try to use two different nixpkgs for
    # different NixOS hosts in the same flake or you'll get a headache
    let
      lib = nixpkgs.lib;
      home-network = fromTOML (builtins.readFile ./home-network.toml);
      mkPkgs = system: import nixpkgs {
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
      };
      mkHost = { system, hostName, modules }:
        let
          pkgs = mkPkgs system;
          configSettings = import ./settings.nix {
            inherit pkgs;
          };
        in
        lib.nixosSystem {
          inherit system pkgs;
          specialArgs = { inherit inputs home-network configSettings; };
          modules = [
            ({ pkgs, ... }: {
              networking.hostName = hostName;
              # Let 'nixos-version --json' know about the Git revision
              # of this flake.
              system.configurationRevision = lib.mkIf (self ? rev) self.rev;
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

      mkHosts = lib.attrsets.mapAttrs (name: value: mkHost (lib.recursiveUpdate { hostName = name; } value));
    in
    {
      nixosConfigurations = mkHosts {
        mars = {
          system = "x86_64-linux";
          modules = [
            nixos-hardware.nixosModules.lenovo-thinkpad-t14-amd-gen1
            nixos-hardware.nixosModules.common-pc-laptop-ssd
            ./hosts/mars/configuration.nix
          ];
        };

        jupiter = {
          system = "x86_64-linux";
          modules = [
            nixos-hardware.nixosModules.common-pc-ssd
            ./hosts/jupiter/configuration.nix
          ];
        };

        ceres = {
          system = "aarch64-linux";
          modules = [
            ./hosts/ceres/configuration.nix
          ];
        };

        saturn = {
          system = "x86_64-linux";
          modules = [
            ./hosts/saturn/configuration.nix
          ];
        };
      };
    };
}
