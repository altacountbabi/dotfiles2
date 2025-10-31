{ inputs, ... }:

{
  flake.nixosModules.base =
    { pkgs, lib, ... }:
    let
      inherit (lib) mkOpt types;
    in
    {
      options.prefs = {
        helium.package =
          mkOpt types.package inputs.helium.defaultPackage.${pkgs.system}
            "The package to use for helium browser";
        helium.autostart =
          mkOpt types.bool false
            "Whether to automatically start helium browser at startup";
      };
    };

  flake.nixosModules.helium =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib) mkIf;
    in
    {
      environment.systemPackages = [
        config.prefs.helium.package
      ];

      prefs.autostart.helium = mkIf config.prefs.helium.autostart config.prefs.helium.package;
    };
}
