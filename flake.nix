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

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wrrr = {
      type = "git";
      url = "https://git-home.5kw.li/foldu/wrrr";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.naersk.follows = "naersk";
      inputs.flake-utils.follows = "flake-utils";
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

    homeserver-sekret = {
      type = "git";
      url = "https://git-home.5kw.li/foldu/sekret";
      flake = false;
    };

    wpp-gtk = {
      type = "git";
      url = "https://git-home.5kw.li/foldu/wpp-gtk";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.naersk.follows = "naersk";
    };

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ble-ws-central = {
      url = "github:foldu/ble-ws-central";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    kitty-themes = {
      url = "github:kovidgoyal/kitty-themes";
      flake = false;
    };
  };

  outputs =
    { self
    , nixpkgs
    , nixos-hardware
    , pickwp
    , wrrr
    , huh
    , flake-utils
    , home-manager
    , naersk
    , blocklistdownloadthing
    , eunzip
    , homeserver-sekret
    , wpp-gtk
    , neovim-nightly-overlay
    , ble-ws-central
    , kitty-themes
    }@inputs:
    # NOTE: don't try to use two different nixpkgs for
    # different NixOS hosts in the same flake or you'll get a headache
    let
      lib = nixpkgs.lib;
      home-network = fromTOML (builtins.readFile ./home-network.toml);
      mylib = import ./lib { inherit lib; };
      mkPkgs = system: import nixpkgs {
        inherit system;
        overlays = [
          pickwp.overlay
          eunzip.overlay
          wrrr.overlay
          wpp-gtk.overlay
          huh.overlay
          blocklistdownloadthing.overlay
          ble-ws-central.overlay
          neovim-nightly-overlay.overlay
          (import ./overlays)
          (import ./overlays/customizations.nix)
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
          specialArgs = { inherit inputs home-network configSettings mylib; };
          modules = [
            (
              { pkgs, ... }: {
                imports = [
                  ./modules
                  ble-ws-central.nixosModule
                ];
                networking.hostName = hostName;
                # Let 'nixos-version --json' know about the Git revision
                # of this flake.
                system.configurationRevision = lib.mkIf (self ? rev) self.rev;
                nix.registry = {
                  nixpkgs.flake = nixpkgs;
                };
                environment.systemPackages = with pkgs; [
                  git
                ];
              }
            )
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
    } // (flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShell = pkgs.mkShell {
        nativeBuildInputs = [
          (pkgs.python39.withPackages
            (p: with p; [ ipython toml plumbum ]))
          pkgs.rsync
        ];
      };
    }
    ));
}
