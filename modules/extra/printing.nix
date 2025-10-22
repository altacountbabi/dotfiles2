{
  flake.nixosModules.printing =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib) mkOpt types;
    in
    {
      options.prefs = {
        printing.drivers = mkOpt (types.listOf types.package) (
          with pkgs;
          [
            gutenprint
            hplip
          ]
        );
      };

      config = {
        services.printing = {
          enable = true;
          inherit (config.prefs.printing) drivers;
        };
      };
    };
}
