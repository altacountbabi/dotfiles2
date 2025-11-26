{ self, ... }:

{
  flake.nixosModules = self.mkModule "keyd" {
    path = "keyd";

    opts =
      { mkOpt, types, ... }:
      {
        swapCapsAndEscape = mkOpt types.bool true "Swaps the caps lock key with the escape key";
      };

    cfg =
      { lib, cfg, ... }:
      {
        services.keyd = {
          enable = true;
          keyboards.default = {
            ids = [ "*" ];
            settings.main = (
              # Switch caps and escape
              lib.optionalAttrs cfg.swapCapsAndEscape {
                capslock = "escape";
                escape = "capslock";
              }
            );
          };
        };
      };
  };
}
