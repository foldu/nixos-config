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

    wscrot = {
      type = "git";
      url = "https://git-home.5kw.li/foldu/wscrot";
      inputs.nixpkgs.follows = "/nixpkgs";
      inputs.naersk.follows = "/naersk";
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
    , wscrot
    , doom-emacs
    }@inputs:
    let
      home-network = fromTOML (builtins.readFile ./home-network.toml);
      mkPkgs = system: import inputs.nixpkgs {
        inherit system;
        overlays = [
          emacs-overlay.overlay
          rust-overlay.overlay
          pickwp.overlay
          wrrr.overlay
          huh.overlay
          (final: prev:
            let
              putput = [
                "wscrot"
              ];
            in
            prev.lib.genAttrs putput (
              name:
              inputs.${name}.defaultPackage.${system}
            )
          )
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
        nixpkgs.lib.nixosSystem
          {
            inherit system pkgs;
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
      };
    } // flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = mkPkgs system;
    in
    {
      devShell = pkgs.mkShell {
        # FIXME: make shell completion work
        buildInputs = [ pkgs.huh ];
      };
    });
}
