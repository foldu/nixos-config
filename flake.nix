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
      type = "git";
      url = "https://lab.home.5kw.li/foldu/pickwp";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
    };

    crane = {
      url = "github:ipetkov/crane/v0.20.0";
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

    nix-stuff = {
      url = "github:foldu/nix-stuff";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        crane.follows = "crane";
      };
    };

    yazi = {
      url = "github:sxyazi/yazi";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    cashewnix.url = "github:foldu/cashewnix";

    src-manage = {
      url = "github:foldu/src-manage";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quadlet-nix = {
      url = "github:SEIAROTg/quadlet-nix";
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
        modules:
        nixpkgs.lib.nixosSystem {
          modules = modules ++ [
            cashewnix.nixosModules.cashewnix
            sops-nix.nixosModules.sops
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
        "barnabas@ceres" = mkHome [ ./home/ceres ] nixpkgs.legacyPackages."aarch64-linux";
        "barnabas@jupiter" = mkHome [ ./home/jupiter ] nixpkgs.legacyPackages."x86_64-linux";
        "barnabas@mars" = mkHome [ ./home/mars ] nixpkgs.legacyPackages."x86_64-linux";
        "barnabas@saturn" = mkHome [ ./home/saturn ] nixpkgs.legacyPackages."x86_64-linux";
        "barnabas@moehre" = mkHome [ ./home/moehre ] nixpkgs.legacyPackages."x86_64-linux";
        "barnabas@venus" = mkHome [ ./home/venus ] nixpkgs.legacyPackages."x86_64-linux";
      };
      nixosConfigurations = {
        "ceres" = mkNixos [ ./nixos/ceres ];
        "jupiter" = mkNixos [ ./nixos/jupiter ];
        "mars" = mkNixos [ ./nixos/mars ];
        "saturn" = mkNixos [ ./nixos/saturn ];
        "moehre" = mkNixos [ ./nixos/moehre ];
        "venus" = mkNixos [ ./nixos/venus ];
      };
      overlays = import ./overlays { inherit inputs; };
      lib = import ./lib { inherit (nixpkgs) lib; };
    };
}
