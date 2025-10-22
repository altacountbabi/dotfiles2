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
        mkOpt
        optionalAttrs
        types
        ;
    in
    {
      options.prefs = {
        nix.package = mkOpt types.package pkgs.nixVersions.latest "The package to use for nix";
        nix.localNixpkgs =
          mkOpt types.bool false
            "Whether to make a local copy of nixpkgs from the flake inputs";

        nix.flakePath =
          mkOpt types.str "/home/${config.prefs.user.name}/conf"
            "The path to the flake containing this config";

        nix.customBinaryCache =
          mkOpt types.bool true
            "Whether to use our custom binary cache as to not re-compile everything for small patches";
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

          registry.conf.to = {
            type = "path";
            path = config.cleanRoot;
          };

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
        environment.shellAliases = {
          switch = "nh os switch";
        };

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
