{ self, ... }:

{
  flake.nixosModules = self.mkModule "bluetooth" {
    path = "bluetooth";

    opts =
      {
        pkgs,
        mkOpt,
        types,
        ...
      }:
      {
        frontend = mkOpt types.package pkgs.bluetui "Which bluetooth management frontend to use";
      };

    cfg =
      {
        pkgs,
        lib,
        cfg,
        ...
      }:
      {
        environment.systemPackages = [
          (lib.hideDesktop {
            inherit pkgs;
            package = cfg.frontend;
          })
        ];

        hardware.bluetooth = {
          enable = true;
          # Show battery charge of Bluetooth devices
          settings.General.Experimental = true;
        };
      };
  };
}
