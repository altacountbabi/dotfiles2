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

        scanning = {
          printers = mkOpt (types.listOf types.str) "" "List of IPs for network scanners";
          backends = mkOpt (types.listOf types.package) (with pkgs; [
            airscan
          ]) "List of SANE backends to install";
        };
      };
    };

  flake.nixosModules.printing =
    { config, lib, ... }:
    {
      services.printing = {
        enable = true;
        inherit (config.prefs.printing) drivers;
      };

      hardware.sane = {
        enable = lib.mkDefault true;
        netConf = config.prefs.scanning.printers |> builtins.concatStringsSep "\n";
        extraBackends = config.prefs.scanning.backends;
      };
    };
}
