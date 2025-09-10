{
  description = "eureka-cpu's nix-darwin config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      type = "github";
      owner = "nix-community";
      repo = "home-manager";
      ref = "release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    nix-watch = {
      url = "github:Cloud-Scythe-Labs/nix-watch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nix-darwin
    , home-manager
    , nixpkgs
    , flake-utils
    , nix-watch
    }:
      with flake-utils.lib;
      eachSystem
        (with system; [
          aarch64-darwin
          x86_64-darwin
        ])
        (system:
        let
          host-name = "yabai";
          pkgs = nixpkgs.legacyPackages.${system};
          inherit (pkgs) lib;

          configuration = import ./configuration.nix {
            inherit system pkgs lib;
            rev = self.rev or self.dirtyRev or null;
          };
        in
        {
          # Rebuild darwin flake using:
          # $ darwin-rebuild switch --flake .#${system}.${host-name}
          darwinConfigurations.${host-name} = nix-darwin.lib.darwinSystem {
            modules = [
              configuration
              home-manager.darwinModules.home-manager
              {
                users.users.eureka = {
                  name = "eureka";
                  home = "/Users/eureka";
                };
              }
              {
                home-manager = {
                  users.eureka = ./home-manager;
                  useUserPackages = true;
                  useGlobalPkgs = true;
                };
              }
            ];
          };

          # Expose the package set, including overlays, for convenience.
          darwinPackages = self.darwinConfigurations.${host-name}.pkgs;

          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              nil
              nixpkgs-fmt
            ] ++ nix-watch.nix-watch.${system}.devTools;
          };

          formatter = pkgs.nixpkgs-fmt;
        });
}
