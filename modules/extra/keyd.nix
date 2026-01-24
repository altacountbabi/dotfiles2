{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".services.keyd";

    opts =
      { mkOpt, types, ... }:
      {
        presets.swapCapsEsc = mkOpt types.bool true "Swaps the caps lock key with the escape key";
      };

    cfg =
      { lib, cfg, ... }:
      {
        services.keyd.keyboards.default = {
          ids = [ "*" ];
          settings.presets = lib.mkMerge [
            (lib.optionalAttrs cfg.presets.swapCapsEsc {
              capslock = "escape";
              escape = "capslock";
            })
          ];
        };
      };
  };
}
