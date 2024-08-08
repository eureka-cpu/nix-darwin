{ system, pkgs, lib, rev, ... }:
{
  environment.systemPackages = with pkgs; [
    helix
    kitty
    kitty-themes
  ];

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;

  system = {
    # Set Git commit hash for darwin-version.
    configurationRevision = rev;
    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    stateVersion = 4;
  };
  security.pam.enableSudoTouchIdAuth = true;

  nix = {
    settings = {
      # Necessary for using flakes on this system.
      experimental-features = "nix-command flakes";
      # Necessary for using `linux-builder`.
      trusted-users = [ "root" "@admin" ];
    };
    # Use the path to `nixpkgs` in `inputs` as $NIX_PATH
    nixPath = lib.mkForce [ "nixpkgs=${pkgs.path}" ];
    package = pkgs.nixVersions.nix_2_22;
    # Linux VM launchd service
    linux-builder.enable = true;
  };

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = system;
}

