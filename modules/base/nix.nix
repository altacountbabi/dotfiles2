{ self, inputs, ... }:

{
  flake.nixosModules = self.mkModule "base" {
    path = "nix";

    opts =
      {
        pkgs,
        config,
        mkOpt,
        types,
        ...
      }:
      {
        package = mkOpt types.package pkgs.nixVersions.latest "The package to use for nix";
        localNixpkgs =
          mkOpt types.bool false
            "Whether to make a local copy of nixpkgs from the flake inputs";

        flakePath =
          mkOpt types.str "/home/${config.prefs.user.name}/conf"
            "The path to the flake containing this config";

        customBinaryCache =
          mkOpt types.bool true
            "Whether to use our custom binary cache as to not re-compile everything for small patches";
      };

    cfg =
      {
        config,
        cfg,
        lib,
        ...
      }:
      {
        nix = {
          inherit (cfg) package;

          settings = {
            experimental-features = [
              "pipe-operators"
              "nix-command"
              "flakes"
            ];
            warn-dirty = false;
          }
          // (lib.optionalAttrs cfg.customBinaryCache {
            substituters = [ "http://av1.space:5000" ];
            trusted-public-keys = [ "av1.space:SUHVEkuXLKtIKjRS1ub/JaoyKeKx+5Sf412aX+jNWFY=" ];
          });

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

              conf.to = {
                type = "path";
                path = config.prefs.cleanRoot;
              };
            };
        };

        system.tools = {
          nixos-option.enable = false;
          nixos-version.enable = false;
        };

        programs.nh.enable = true;
        environment.sessionVariables.NH_FLAKE = config.prefs.nix.flakePath;
        environment.shellAliases = {
          switch = "nh os switch";
        };

        systemd.services.copy-nixpkgs = lib.mkIf config.prefs.nix.localNixpkgs {
          description = "copy nixpkgs to store early";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          wantedBy = [ "basic.target" ];
          serviceConfig = {
            Type = "simple";
            ExecStart = "/run/current-system/sw/bin/nix eval nixpkgshello";
          };
        };

        nixpkgs = {
          config.allowUnfree = true;
          overlays = self.overlays |> builtins.attrValues;
        };

        documentation.enable = false;

        system.stateVersion = "25.11";
      };
  };
}
