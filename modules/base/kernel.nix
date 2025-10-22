{
  flake.nixosModules.base =
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
      # TODO: Add kernel customization options (disabling VT, cpu-native optimisations, etc..)
      options.prefs = {
        kernel.latest = mkOpt types.bool true "Whether to use the latest kernel or the LTS kernel.";
        kernel.params = mkOpt (types.listOf types.str) [ ] "Parameters added to the kernel command line.";
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
