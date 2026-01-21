{
  flake.nixosModules.dms =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.programs.dms-shell;
      inherit (lib) mkOpt types;
    in
    {
      options.programs.dms-shell =
        let
          json = pkgs.formats.json { };
        in
        {
          settings = mkOpt (types.attrsOf json.type) { } "DMS settings";
          session = mkOpt (types.attrsOf json.type) { } "DMS session data";
        };

      config = {
        programs.dms-shell = {
          enable = true;
          systemd.enable = false;

          enableSystemMonitoring = true;
          enableVPN = true;
          enableDynamicTheming = true;
          enableAudioWavelength = true;
          enableCalendarEvents = true;

          session.wallpaperPath =
            let
              wallpaper = config.prefs.theme.wallpaper;
            in
            lib.mkIf (wallpaper != null) wallpaper;

          settings =
            let
              dmsTheme =
                (with config.prefs.theme.colors; {
                  name = "Nix";

                  primary = accent;
                  primaryText = base;

                  primaryContainer = lavender;

                  secondary = accent;
                  surfaceTint = accent;

                  background = mantle;
                  backgroundText = text;

                  surface = base;
                  surfaceText = text;

                  surfaceVariant = surface1;
                  surfaceVariantText = subtext1;

                  surfaceContainer = base;
                  surfaceContainerHigh = surface0;
                  surfaceContainerHighest = surface1;

                  outline = overlay0;

                  error = red;
                  warning = yellow;
                  info = blue;

                  matugen_type = "scheme-expressive";
                })
                |> (pkgs.formats.json { }).generate "dms-theme";
            in
            {
              customThemeFile = toString dmsTheme;
              currentThemeName = "custom";
              widgetBackgroundColor = "sch";
              widgetColorMode = "default";

              useAutoLocation = true;

              soundsEnabled = false;
            };
        };

        programs.dsearch = {
          enable = true;
          systemd = {
            enable = true;
            target = "graphical-session.target";
          };
        };

        prefs.merged-configs = with config.prefs.user; {
          dms = {
            path = "${home}/.config/DankMaterialShell/settings.json";
            overlay = cfg.settings;
          };
          dms-session = {
            path = "${home}/.config/DankMaterialShell/session.json";
            overlay = cfg.session;
          };
        };

        programs.niri.settings.binds =
          {
            "Mod+Space" = "dms ipc spotlight toggle";
            "Mod+Shift+V" = "dms ipc clipboard toggle";
            "Mod+N" = "dms ipc notifications toggle";
            "Mod+P" = "dms ipc powermenu toggle";
            "Mod+L" = "dms ipc lock lock";
          }
          |> lib.mapAttrs (
            k: v: {
              spawn = lib.splitString " " v;
            }
          );

        prefs.autostart = [
          "dms run -d; until dms ipc lock lock; do sleep 0.1; done"
        ];
      };
    };
}
