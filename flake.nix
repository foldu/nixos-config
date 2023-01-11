{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pickwp = {
      type = "git";
      url = "https://git.home.5kw.li/foldu/pickwp";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.crane.follows = "crane";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
    };

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    atchr = {
      type = "git";
      url = "https://git.home.5kw.li/foldu/atchr";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.crane.follows = "crane";
      inputs.flake-utils.follows = "flake-utils";
    };

    huh = {
      url = "github:foldu/huh";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.crane.follows = "crane";
      inputs.flake-utils.follows = "flake-utils";
    };

    eunzip = {
      url = "github:foldu/eunzip";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.crane.follows = "crane";
      inputs.flake-utils.follows = "flake-utils";
    };

    blocklistdownloadthing = {
      url = "github:foldu/blocklistdownloadthing";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.crane.follows = "crane";
      inputs.flake-utils.follows = "flake-utils";
    };

    homeserver-sekret = {
      type = "git";
      url = "https://git.home.5kw.li/foldu/sekret";
      flake = false;
    };

    wpp-gtk = {
      type = "git";
      url = "https://git.home.5kw.li/foldu/wpp-gtk";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      #inputs.nixpkgs.follows = "nixpkgs";
      # Pin to a nixpkgs revision that doesn't have NixOS/nixpkgs#208103 yet
      inputs.nixpkgs.url = "github:nixos/nixpkgs?rev=fad51abd42ca17a60fc1d4cb9382e2d79ae31836";
    };

    kitty-themes = {
      url = "github:kovidgoyal/kitty-themes";
      flake = false;
    };

    kanagawa-theme = {
      url = "github:rebelot/kanagawa.nvim";
      flake = false;
    };

    random-scripts = {
      url = "https://git.home.5kw.li/foldu/random-scripts";
      type = "git";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.crane.follows = "crane";
    };

    nix-serve-ng = {
      url = "github:aristanetworks/nix-serve-ng";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    peerix = {
      url = "github:cid-chan/peerix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-stuff = {
      url = "github:foldu/nix-stuff";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , nixos-hardware
    , pickwp
    , atchr
    , huh
    , flake-utils
    , home-manager
    , crane
    , blocklistdownloadthing
    , eunzip
    , homeserver-sekret
    , wpp-gtk
    , neovim-nightly-overlay
    , kitty-themes
    , kanagawa-theme
    , random-scripts
    , nix-serve-ng
    , peerix
    , nix-stuff
    }@inputs:
    # NOTE: don't try to use two different nixpkgs for
    # different NixOS hosts in the same flake or you'll get a headache
    let
      lib = nixpkgs.lib;
      home-network = fromTOML (builtins.readFile ./home-network.toml);
      mylib = import ./lib { inherit lib; };
      mkPkgs = system: import nixpkgs {
        inherit system;
        overlays =
          let
            otherPkgs = lib.foldl (acc: x: acc // x.packages.${system}) { } [
              nix-stuff
              eunzip
              blocklistdownloadthing
              pickwp
              wpp-gtk
              huh
              random-scripts
              peerix
            ];
          in
          [
            neovim-nightly-overlay.overlay
            (final: prev: otherPkgs)
            (import ./overlays)
            (import ./overlays/customizations.nix)
          ] ++ nix-serve-ng.overlays.override;
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
          modules =
            [
              (
                { pkgs, ... }: {
                  imports = [
                    ./modules
                    nix-stuff.nixosModules.netclient
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
            ./hosts/mars/configuration.nix
          ];
        };

        jupiter = {
          system = "x86_64-linux";
          modules = [
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
