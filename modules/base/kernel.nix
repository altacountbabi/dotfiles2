{ self, ... }:

{
  flake.nixosModules = self.mkModule "base" {
    path = "kernel";

    opts =
      { mkOpt, types, ... }:
      {
        latest = mkOpt types.bool true "Whether to use the latest kernel or the LTS ";
        params = mkOpt (types.listOf types.str) [ ] "Parameters added to the kernel command line.";
      };

    cfg =
      { cfg, pkgs, ... }:
      {
        boot = {
          kernelPackages = if cfg.latest then pkgs.linuxPackages_latest else pkgs.linuxPackages;
          kernelParams = cfg.params;
        };
      };
  };
}
