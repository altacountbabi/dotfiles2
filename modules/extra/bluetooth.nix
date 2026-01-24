{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".hardware.bluetooth";

    opts =
      { mkOpt, types, ... }:
      {
        frontend = mkOpt (types.nullOr types.package) null "Which bluez client to use";
      };

    cfg =
      {
        pkgs,
        lib,
        cfg,
        ...
      }:
      {
        environment.systemPackages = lib.mkIf (cfg.frontend != null) [
          (lib.hideDesktop {
            inherit pkgs;
            package = cfg.frontend;
          })
        ];

        hardware.bluetooth = {
          settings.General.Experimental = lib.mkDefault true;
        };
      };
  };
}
