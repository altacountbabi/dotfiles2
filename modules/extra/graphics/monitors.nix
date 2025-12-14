{ self, ... }:

{
  flake.nixosModules =
    (self.mkModule "base" {
      opts =
        {
          config,
          mkOpt,
          types,
          ...
        }:
        {
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

                color = mkOpt types.str config.prefs.theme.colors.mantle ''
                  The background color to use for the monitor when no wallpaper is set.
                  Defaults to the `mantle` color in the current theme.
                '';

                vrr = mkOpt types.bool false ''
                  Whether to enable VRR (Variable Refresh Rate).
                  Disabled by default as it can cause flickering on certain monitors.
                '';

                edid = mkOpt (types.nullOr types.str) null ''
                  Path to EDID file for this monitor output.
                  If set, will be used to assign custom EDID to the output.
                '';
              };
            }
          )) { } "Host-specific monitor config";
        };

      cfg =
        { cfg, lib, ... }:
        {
          hardware.display.outputs =
            cfg.monitors
            |> lib.filterAttrs (_: m: m.enable)
            |> lib.mapAttrs (
              _: monitor: {
                edid = monitor.edid;
                mode = "${toString monitor.width}x${toString monitor.height}@${toString monitor.refreshRate}";
              }
            );
        };
    })
    // {
      vm-monitor = {
        prefs.monitors."Virtual-1" = {
          width = 1920;
          height = 1080;
        };
      };
    };
}
