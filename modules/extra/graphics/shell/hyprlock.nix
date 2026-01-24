{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".programs.hyprlock";

    opts =
      { mkOpt, types, ... }:
      with types;
      {
        autostart = mkOpt bool true "Whether to make hyprlock autostart to act as the login screen";

        settings = mkOpt (
          let
            valueType =
              nullOr (oneOf [
                bool
                int
                float
                str
                path
                (attrsOf valueType)
                (listOf valueType)
              ])
              // {
                description = "Hyprlock configuration value";
              };
          in
          valueType
        ) { } "Hyprlock settings.\nSee <https://wiki.hypr.land/Hypr-Ecosystem/hyprlock/>";

        sourceFirst = mkOpt bool true "Whether to put source entries at the top of the configuration";

        importantPrefixes = mkOpt (listOf str) [
          "$"
          "bezier"
          "monitor"
          "size"
        ] "List of prefix of attributes to source at the top of the config.";
      };

    cfg =
      {
        config,
        lib,
        cfg,
        ...
      }:
      {
        config = lib.mkIf cfg.enable {
          programs.hyprlock.settings = lib.mkDefault (
            let
              color = x: "rgb(${lib.stripHex x})";
              inherit (config.prefs.theme) wallpaper;
            in
            with config.prefs.theme.colors;
            {
              general = {
                hide_cursor = true;
                disable_loading_bar = true;
              };

              animations = {
                enabled = true;
                bezier = "linear, 1, 1, 0, 0";
                animation = [
                  "fade, 0"
                  "fadeIn, 1, 5, linear"
                  "fadeOut, 1, 5, linear"
                  "inputFieldDots, 1, 1, linear"
                ];
              };

              background = (
                {
                  color = color base;
                }
                // (lib.optionalAttrs (wallpaper != null) {
                  path = wallpaper;
                })
              );

              input-field = {
                size = "15%, 5%";
                outline_thickness = 3;
                inner_color = "rgba(0, 0, 0, 0.0)";

                outer_color = color surface1;
                check_color = color surface1;
                fail_color = color red;

                font_color = color text;

                fade_on_empty = false;
                rounding = "100%";

                font_family = "Noto Sans Bold";
                placeholder_text = "Password";
                fail_text = "$PAMFAIL";

                dots_spacing = 0.3;

                position = "0, -20";
                halign = "center";
                valign = "center";
              };

              # Time
              label = [
                {
                  text = "$TIME";
                  color = color text;
                  font_family = "Noto Sans Bold";
                  font_size = 75;

                  position = "0, 175";
                  halign = "center";
                  valign = "center";
                }

                # Date
                {
                  text = ''cmd[update:60000] date "+%A %B %d"'';
                  color = color text;
                  font_family = "Noto Sans Semibold";
                  font_size = 20;

                  position = "0, 100";
                  halign = "center";
                  valign = "center";
                }
              ];
            }
          );

          environment.etc."xdg/hypr/hyprlock.conf" =
            let
              shouldGenerate = cfg.settings != { };
            in
            lib.mkIf shouldGenerate {
              text =
                (lib.toHyprconf {
                  attrs = cfg.settings;
                  importantPrefixes = cfg.importantPrefixes ++ lib.optional cfg.sourceFirst "source";
                })
                |> lib.optionalString (cfg.settings != { });
            };

          programs.niri.settings.binds."Mod+L".spawn = lib.getExe cfg.package;

          prefs.autostart = [ cfg.package ];
        };
      };
  };
}
