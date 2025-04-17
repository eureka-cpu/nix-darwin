{ system, pkgs, lib, rev, ... }:
{
  environment.systemPackages = with pkgs; [
    git
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
      # Extra artifact caches
      extra-substituters = [ "https://cloud-scythe-labs.cachix.org" ];
      extra-trusted-public-keys = [
        "cloud-scythe-labs.cachix.org-1:I+IM+x2gGlmNjUMZOsyHJpxIzmAi7XhZNmTVijGjsLw="
      ];
      # Necessary for using `linux-builder`.
      trusted-users = [ "root" "@admin" ];
    };
    # Use the path to `nixpkgs` in `inputs` as $NIX_PATH
    nixPath = lib.mkForce [ "nixpkgs=${pkgs.path}" ];
    package = pkgs.nixVersions.latest;
    # Linux VM launchd service
    linux-builder.enable = true;
  };

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = system;

  # The default Nix build user ID range has been adjusted for
  # compatibility with macOS Sequoia 15. Your _nixbld1 user currently has
  # UID 301 rather than the new default of 351.
  #
  # You can automatically migrate the users with the following command:
  #
  # curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- repair sequoia --move-existing-users
  #
  # If you have no intention of upgrading to macOS Sequoia 15, or already
  # have a custom UID range that you know is compatible with Sequoia, you
  # can disable this check by setting:
  ids.uids.nixbld = 300;
}

