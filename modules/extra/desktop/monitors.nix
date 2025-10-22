{
  flake.nixosModules.base =
    {
      lib,
      ...
    }:
    let
      inherit (lib) mkOpt types;
    in
    {
      options.prefs = {
        monitors = mkOpt (types.attrsOf (
          types.submodule {
            options = {
              enable = mkOpt types.bool true "Whether the monitor should be enabled or not";

              width = mkOpt types.int 1920 "Width of the monitor";
              height = mkOpt types.int 1080 "Height of the monitor";

              refreshRate = mkOpt types.float 60.0 "Refresh rate of the monitor";
              scale = mkOpt types.float 1.0 "How much to scale the monitor";

              x = mkOpt types.int 0 "How to position the monitor virtually on the X axis";
              y = mkOpt types.int 0 "How to position the monitor virtually on the Y axis";
              transform = mkOpt (types.enum [
                "normal"
                90
                180
                270
                "flipped"
                "flipped-90"
                "flipped-180"
                "flipped-270"
              ]) "normal" "How to rotate/transform the monitor";

              vrr = mkOpt types.bool false ''
                Whether to enable VRR (Variable Refresh Rate).
                Disabled by default as it can cause flickering on certain monitors.
              '';
            };
          }
        )) { } "Host-specific monitor config";
      };
    };
}
