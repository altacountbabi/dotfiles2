{
  flake.nixosModules.base =
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
      # TODO: Add kernel customization options (disabling VT, cpu-native optimisations, etc..)
      options.prefs = {
        kernel.latest = mkOption {
          type = types.bool;
          default = true;
        };

        kernel.params = mkOption {
          type = types.listOf types.str;
          default = [ ];
        };
      };

      config = {
        boot = {
          kernelPackages =
            if config.prefs.kernel.latest then pkgs.linuxPackages_latest else pkgs.linuxPackages;

          kernelParams = config.prefs.kernel.params;
        };
      };
    };
}
