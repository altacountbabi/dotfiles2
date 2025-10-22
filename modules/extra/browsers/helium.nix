{ inputs, ... }:

{
  flake.nixosModules.helium =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkOpt types;
    in
    {
      options.prefs = {
        helium.package =
          mkOpt types.package inputs.helium.defaultPackage.${pkgs.system}
            "The package to use for helium browser";
      };

      config = {
        environment.systemPackages = [
          config.prefs.helium.package
        ];
      };
    };
}
