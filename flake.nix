{
  description = "eureka-cpu nix-darwin config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nix-darwin, nixpkgs, flake-utils }:
  let
    host-name = "yabai";
    system = flake-utils.lib.system.aarch64-darwin;
    pkgs = nixpkgs.legacyPackages.${system};
    configuration = import ./configuration.nix {
      inherit system pkgs;
      rev = self.rev or self.dirtyRev or null;
    };
  in
  {
    # Rebuild darwin flake using:
    # $ darwin-rebuild switch --flake .
    darwinConfigurations."${host-name}" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."${host-name}".pkgs;
  };
}
