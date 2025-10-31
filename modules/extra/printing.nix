{
  flake.nixosModules.base =
    { pkgs, lib, ... }:
    let
      inherit (lib) mkOpt types;
    in
    {
      options.prefs = {
        printing.drivers = mkOpt (types.listOf types.package) (with pkgs; [
          gutenprint
          hplip
        ]) "List of printer drivers to install";
      };
    };

  flake.nixosModules.printing =
    { config, ... }:
    {
      services.printing = {
        enable = true;
        inherit (config.prefs.printing) drivers;
      };
    };
}
