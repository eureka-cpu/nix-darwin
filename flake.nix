{
  description = "eureka-cpu's nix-darwin config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    nix-watch = {
      url = "github:Cloud-Scythe-Labs/nix-watch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nix-darwin, nixpkgs, flake-utils, nix-watch }:
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
            modules = [ configuration ];
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
