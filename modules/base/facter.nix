{ inputs, ... }:

{
  flake.nixosModules.base =
    { lib, ... }:
    let
      inherit (lib) mkOpt types;
    in
    {
      options.prefs = {
        facterReport = mkOpt (types.nullOr types.path) null "Path to facter report";
      };
    };

  flake.nixosModules.facter =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib) mkIf;
    in
    {
      imports = [
        inputs.nixos-facter-modules.nixosModules.facter
      ];

      config = {
        facter.reportPath = mkIf (config.prefs.facterReport != null) config.prefs.facterReport;
      };
    };
}
