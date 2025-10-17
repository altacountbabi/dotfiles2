{ self, ... }:

{
  flake.nixosModules.niri =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib) mkOption types;
    in
    {
      options.prefs = {
        niri.package = mkOption {
          type = types.package;
          default = self.packages.${pkgs.system}.niri;
        };
      };

      config = {
        programs.niri = {
          enable = true;
          package = config.prefs.niri.package;
        };
      };
    };
}
