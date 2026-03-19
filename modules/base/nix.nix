{ self, inputs, ... }:

{
  flake.nixosModules = self.mkModule {
    path = "nix";

    opts =
      {
        config,
        mkOpt,
        types,
        ...
      }:
      {
        localNixpkgs =
          mkOpt types.bool false
            "Whether to make a local copy of nixpkgs from the flake inputs";

        flakePath =
          mkOpt types.str "${config.prefs.user.home}/conf"
            "The path to the flake containing this config";

        customBinaryCache =
          mkOpt types.bool true
            "Whether to use our custom binary cache as to not re-compile everything for small patches";
      };

    cfg =
      {
        config,
        pkgs,
        lib,
        cfg,
        ...
      }:
      {
        nix = {
          package = inputs.detnix.packages.${pkgs.stdenv.hostPlatform.system}.default;

          settings = {
            experimental-features = [
              "pipe-operators"
              "nix-command"
              "flakes"
            ];
            warn-dirty = false;
          };
          # TODO: Ideally we dont need this, this is also broken at the moment
          # // (lib.optionalAttrs cfg.customBinaryCache {
          #   substituters = [ "https://av1.space" ];
          #   trusted-public-keys = [ "av1.space:SUHVEkuXLKtIKjRS1ub/JaoyKeKx+5Sf412aX+jNWFY=" ];
          # });

          gc = {
            automatic = true;
            dates = "weekly";
            options = "--delete-older-than 7d";
          };

          optimise = {
            automatic = true;
            dates = "weekly";
          };

          channel.enable = false;

          registry =
            let
              to = lib.mkForce (
                if cfg.localNixpkgs then
                  {
                    type = "path";
                    path = inputs.nixpkgs.outPath;
                  }
                else
                  {
                    type = "github";
                    owner = "nixos";
                    repo = "nixpkgs";
                    rev = inputs.nixpkgs.rev;
                  }
              );
            in
            {
              # Alias `p` to `nixpkgs` to shorten nix3 commands
              p.to = to;
              nixpkgs.to = to;
            };
        };

        system.tools = {
          nixos-option.enable = false;
          nixos-version.enable = false;
          nixos-generate-config.enable = false;
        };

        programs.nh.enable = true;
        environment = {
          sessionVariables =
            with config.nixpkgs.config;
            let
              bool = x: if x then "1" else "0";
            in
            {
              NH_FLAKE = config.prefs.nix.flakePath;
              NIXPKGS_ALLOW_UNFREE = bool allowUnfree;
              NIXPKGS_ALLOW_BROKEN = bool allowBroken;
              NIXPKGS_ALLOW_INSECURE = bool allowInsecure;
            };
          shellAliases.switch = "nh os switch";
        };

        programs.nushell = {
          excludedAliases = lib.mkIf config.isDroid [ "switch" ];
          extraConfig =
            lib.mkIf config.isDroid # nu
              ''
                source ${self.packages.${pkgs.stdenv.hostPlatform.system}.nix-on-droid-switch}/bin/switch
              '';
        };

        systemd.services.copy-nixpkgs = lib.mkIf config.prefs.nix.localNixpkgs {
          description = "copy nixpkgs to store early";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          wantedBy = [ "basic.target" ];
          serviceConfig = {
            Type = "simple";
            ExecStart = "/run/current-system/sw/bin/nix eval nixpkgs#hello";
          };
        };

        nixpkgs = {
          config = {
            allowUnfree = true;
            allowBroken = false;
            allowInsecure = false;
          };
          overlays = lib.attrValues self.overlays;
        };

        documentation.info.enable = false;
        documentation.nixos.enable = false;

        system.stateVersion = "25.11";
      };
  };
}
