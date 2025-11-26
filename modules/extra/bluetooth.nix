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
      { cfg, ... }:
      {
        environment.systemPackages = [
          cfg.frontend
        ];

        hardware.bluetooth = {
          enable = true;
          # Show battery charge of Bluetooth devices
          settings.General.Experimental = true;
        };

        services.blueman.enable = true;
      };
  };
}
