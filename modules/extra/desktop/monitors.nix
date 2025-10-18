{
  flake.nixosModules.base =
    {
      lib,
      ...
    }:
    let
      inherit (lib) mkOption types;
    in
    {
      options.prefs = {
        monitors = mkOption {
          type = types.attrsOf (
            types.submodule {
              options = {
                width = mkOption {
                  type = types.int;
                  example = 1920;
                };
                height = mkOption {
                  type = types.int;
                  example = 1080;
                };
                refreshRate = mkOption {
                  type = types.float;
                  default = 60.0;
                };
                scale = mkOption {
                  type = types.float;
                  default = 1.0;
                };
                transform = mkOption {
                  type = types.enum [
                    "normal"
                    90
                    180
                    270
                    "flipped"
                    "flipped-90"
                    "flipped-180"
                    "flipped-270"
                  ];
                  default = "normal";
                };
                x = mkOption {
                  type = types.int;
                  default = 0;
                };
                y = mkOption {
                  type = types.int;
                  default = 0;
                };
                vrr = mkOption {
                  type = types.bool;
                  default = false;
                };
                enabled = mkOption {
                  type = types.bool;
                  default = true;
                };
              };
            }
          );
          default = { };
        };
      };
    };
}
