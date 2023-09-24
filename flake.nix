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

    homeserver-sekret = {
      type = "git";
      url = "https://git.home.5kw.li/foldu/sekret";
      flake = false;
    };

    wpp-gtk = {
      type = "git";
      url = "https://git.home.5kw.li/foldu/wpp-gtk";
      inputs.flake-utils.follows = "flake-utils";
      inputs.crane.follows = "crane";
      inputs.nixpkgs.follows = "nixpkgs";
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

    nix-stuff = {
      url = "github:foldu/nix-stuff";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        crane.follows = "crane";
      };
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helix = {
      url = "github:helix-editor/helix";
    };

    yazi = {
      url = "github:sxyazi/yazi";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , deploy-rs
    , ...
    }@inputs:
    let
      inherit (self) outputs;
      home-network = fromTOML (builtins.readFile ./home-network.toml);
      getSettings = import ./settings.nix;
      mkHome = modules: pkgs:
        home-manager.lib.homeManagerConfiguration {
          inherit modules pkgs;
          extraSpecialArgs = { inherit inputs outputs home-network getSettings; };
        };
      mkNixos = modules: nixpkgs.lib.nixosSystem {
        inherit modules;
        specialArgs = { inherit inputs outputs home-network getSettings; };
      };
      mkNode = arch: name: {
        hostname = home-network.devices.${name}.dns;
        fastConnection = true;
        magicRollback = false;
        sshOpts = [ "-t" ];
        profilesOrder = [ "system" "home" ];
        profiles = {
          system = {
            sshUser = "barnabas";
            path =
              deploy-rs.lib.${arch}.activate.nixos self.nixosConfigurations.${name};
            user = "root";
          };
          home = {
            sshUser = "barnabas";
            path = deploy-rs.lib.${arch}.activate.home-manager self.homeConfigurations."barnabas@${name}";
            user = "barnabas";
          };
        };
      };
    in
    {
      homeConfigurations = {
        "barnabas@ceres" = mkHome [ ./home/ceres ] nixpkgs.legacyPackages."aarch64-linux";
        "barnabas@jupiter" = mkHome [ ./home/jupiter ] nixpkgs.legacyPackages."x86_64-linux";
        "barnabas@mars" = mkHome [ ./home/mars ] nixpkgs.legacyPackages."x86_64-linux";
        "barnabas@saturn" = mkHome [ ./home/saturn ] nixpkgs.legacyPackages."x86_64-linux";
      };
      nixosConfigurations = {
        "ceres" = mkNixos [ ./nixos/ceres ];
        "jupiter" = mkNixos [ ./nixos/jupiter ];
        "mars" = mkNixos [ ./nixos/mars ];
        "saturn" = mkNixos [ ./nixos/saturn ];
      };
      overlays = import ./overlays { inherit inputs; };
      lib = import ./lib { inherit (nixpkgs) lib; };

      # enable this if you want to evaluate all systems at once lol
      # checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
      deploy.nodes = {
        ceres = mkNode "aarch64-linux" "ceres";
        jupiter = mkNode "x86_64-linux" "jupiter";
        mars = mkNode "x86_64-linux" "mars";
        saturn = mkNode "x86_64-linux" "saturn";
      };
    };
}
