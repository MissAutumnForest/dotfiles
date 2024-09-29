{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager }:
  let
    configuration = { pkgs, ... }: {
      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes repl-flake";

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;

      # Enable Touch ID for sudo
      security = {
        pam.enableSudoTouchIdAuth = true;
      };

      system = {
        defaults = {
          dock.autohide = true;
          dock.mru-spaces = false;
          finder.AppleShowAllExtensions = true;
          finder.FXPreferredViewStyle = "clmv";
          loginwindow.LoginwindowText = "Hello Autumn!";
          screencapture.location = "~/Pictures/screenshots";
        };
        keyboard = {
          enableKeyMapping = true;
          remapCapsLockToEscape = true;
        };

        # Set Git commit hash for darwin-version.
        configurationRevision = self.rev or self.dirtyRev or null;

        # Used for backwards compatibility, please read the changelog before changing.
        stateVersion = 5;
      };

      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = [
        pkgs.tree
        pkgs.wget
        pkgs.tmux
        pkgs.neovim
        pkgs.stow
        pkgs.fzf
      ];

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;  # default shell on catalina

      # home-manager configuration
      users.users.autumn = {
        name = "autumn";
        home = "/Users/autumn";
      };
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#autumn-mbp.local
    darwinConfigurations."autumn-mbp" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        
        home-manager.darwinModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.users.autumn = { pkgs, ... }: {
            home.packages = [
              pkgs.iterm2
              pkgs.gh
            ];

            # The state version is required and should stay at the version you
            # originally installed.
            home.stateVersion = "24.05";
          };
        }
      ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."autumn-mbp".pkgs;
  };
}
