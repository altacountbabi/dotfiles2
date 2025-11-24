{ inputs, ... }:

{
  flake.nixosModules.base =
    { pkgs, lib, ... }:
    let
      inherit (lib) mkOpt types;
    in
    {
      options.prefs = {
        apps.helium = {
          package =
            mkOpt types.package inputs.helium.defaultPackage.${pkgs.stdenv.hostPlatform.system}
              "The package to use for helium browser";
          autostart = mkOpt types.bool false "Whether to automatically start helium browser at startup";
          default = mkOpt types.bool false "Whether to have helium browser be the default browser";
        };
      };
    };

  flake.nixosModules.helium =
    {
      config,
      lib,
      ...
    }:
    {
      prefs.apps.helium.default = true;

      environment.systemPackages = [
        config.prefs.apps.helium.package
      ];

      prefs.autostart.helium = lib.mkIf config.prefs.apps.helium.autostart config.prefs.apps.helium.package;
    };
}
