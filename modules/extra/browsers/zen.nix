{ inputs, ... }:

{
  flake.nixosModules.zen =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkOption types;
    in
    {
      options.prefs = {
        zen.package = mkOption {
          type = types.package;
          default = inputs.zen-browser.packages.${pkgs.system}.default;
        };
      };

      config = {
        environment.systemPackages = [
          config.prefs.zen.package
        ];

        prefs.autostart.zen = config.prefs.zen.package;

        # TODO: Create profile with hjem
      };
    };
}
