{ self, ... }:

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
      inherit (lib)
        mkOpt
        types
        getExe
        mkIf
        ;

      json = pkgs.formats.json { };
      settings = json.generate "dms-settings" cfg.settings;
      session = json.generate "dms-session-data" cfg.session;

      applyConfig =
        self.lib.nushellScript {
          inherit pkgs;
          name = "apply-config";
          text = builtins.readFile ./apply-config.nu;
        }
        |> getExe;

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
      options.programs.dms-shell = {
        settings = mkOpt (types.attrsOf json.type) { } "DMS settings";
        session = mkOpt (types.attrsOf json.type) { } "DMS session data";
      };

      config = {
        programs.dms-shell = {
          enable = true;
          systemd.enable = false;

          enableSystemMonitoring = true; # System monitoring widgets (dgop)
          enableClipboard = true; # Clipboard history manager
          enableVPN = true; # VPN management widget
          enableDynamicTheming = true; # Wallpaper-based theming (matugen)
          enableAudioWavelength = true; # Audio visualizer (cava)
          enableCalendarEvents = true; # Calendar integration (khal)

          session.wallpaperPath =
            let
              wallpaper = config.prefs.theme.wallpaper;
            in
            mkIf (wallpaper != null) wallpaper;

          settings = {
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

        systemd.user.services = {
          dms-config = {
            description = "Apply DMS settings to settings.json";
            after = [ "default.target" ];
            wantedBy = [ "default.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "${applyConfig} ${config.prefs.user.home}/.config/DankMaterialShell/settings.json ${settings}";
            };
          };

          dms-session-data = {
            description = "Apply DMS session data to session.json";
            after = [ "default.target" ];
            wantedBy = [ "default.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "${applyConfig} ${config.prefs.user.home}/.local/state/DankMaterialShell/session.json ${session}";
            };
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
