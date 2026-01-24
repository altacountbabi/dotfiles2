{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    path = "kernel";

    opts =
      { mkOpt, types, ... }:
      {
        latest = mkOpt types.bool true "Whether to use the latest kernel or the LTS";
        params = mkOpt (types.listOf types.str) [ ] "Parameters added to the kernel command line.";

        enableI2C = mkOpt types.bool true "Whether to enable the `i2c-dev` kernel module";
      };

    cfg =
      {
        pkgs,
        lib,
        cfg,
        ...
      }:
      {
        boot = {
          kernelPackages = if cfg.latest then pkgs.linuxPackages_latest else pkgs.linuxPackages;
          kernelParams = cfg.params;

          kernelModules = (lib.optional cfg.enableI2C "i2c-dev");
        };
      };
  };
}
