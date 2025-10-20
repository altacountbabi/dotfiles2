{ self, inputs, ... }:

{
  flake.nixosModules.base =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib)
        mkIf
        mkOption
        mkEnableOption
        mkDefaultEnableOption
        optionalAttrs
        types
        ;
    in
    {
      options.prefs = {
        nix.package = mkOption {
          type = types.package;
          default = pkgs.nixVersions.latest;
        };

        nix.localNixpkgs = mkEnableOption "local nixpkgs";

        nix.flakePath = mkOption {
          type = types.str;
          default = "/home/${config.prefs.user.name}/conf";
        };

        nix.customBinaryCache = mkDefaultEnableOption "use custom binary cache";
      };

      config = {
        nix = {
          inherit (config.prefs.nix) package;
          settings =
            {
              experimental-features = [
                "pipe-operators"
                "nix-command"
                "flakes"
              ];
              warn-dirty = false;
            }
            // (optionalAttrs config.prefs.nix.customBinaryCache {
              substituters = [ "http://av1.space:5000" ];
              trusted-public-keys = [ "av1.space:SUHVEkuXLKtIKjRS1ub/JaoyKeKx+5Sf412aX+jNWFY=" ];
            });
          channel.enable = false;
          registry.nixpkgs.to = lib.mkForce (
            if config.prefs.nix.localNixpkgs then
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
        };

        programs.nh.enable = true;
        environment.sessionVariables.NH_FLAKE = config.prefs.nix.flakePath;

        systemd.services.copy-nixpkgs = mkIf config.prefs.nix.localNixpkgs {
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
          config.allowUnfree = true;
          overlays = self.overlays |> builtins.attrValues;
        };

        documentation.enable = false;

        system.stateVersion = "25.11";
      };
    };
}
