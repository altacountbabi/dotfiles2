{ inputs, ... }:

{
  flake.nixosModules.facter =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib) mkIf mkOpt types;
    in
    {
      imports = [
        inputs.nixos-facter-modules.nixosModules.facter
      ];

      options.prefs.facterReport = mkOpt (types.nullOr types.path) null "Path to facter report";

      config = {
        facter.reportPath = mkIf (config.prefs.facterReport != null) config.prefs.facterReport;
      };
    };
}
