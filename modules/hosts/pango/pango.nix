{ self, ... }:

{
  flake.nixosModules.pango =
    { lib, ... }:
    {
      imports = lib.mkHost (
        with self.nixosModules;
        {
          profile = self.profiles.desktop ++ self.profiles.desktopApps;
          include = [
            pangoHardware
            base16-default-dark-theme
          ];
          exclude = [
            green-theme
            keyd
            zen
          ];
        }
      );

      networking.hostName = "pango";

      programs.dms-shell.settings = {
        barConfigs = [
          {
            id = "default";
            name = "Main Bar";
            enabled = true;
            position = 1; # Bottom
            screenPreferences = [
              "all"
            ];
            showOnLastDisplay = true;
            leftWidgets = [
              "launcherButton"
              "workspaceSwitcher"
              "focusedWindow"
            ];
            centerWidgets = [
              "music"
              "clock"
              "weather"
            ];
            rightWidgets = [
              "systemTray"
              "clipboard"
              "notificationButton"
              "controlCenterButton"
            ];
            spacing = 0;
            innerPadding = 4;
            bottomGap = 0;
            transparency = 1;
            widgetTransparency = 1;
            squareCorners = true;
            noBackground = false;
            gothCornersEnabled = false;
            gothCornerRadiusOverride = false;
            gothCornerRadiusValue = 12;
            borderEnabled = false;
            borderColor = "surfaceText";
            borderOpacity = 1;
            borderThickness = 1;
            fontScale = 1;
            autoHide = false;
            autoHideDelay = 250;
            openOnOverview = false;
            visible = true;
            popupGapsAuto = true;
            popupGapsManual = 4;
          }
        ];
      };

      programs.niri.settings = {
        workspaces.void = {
          layout.background-color = "#000000";
        };
        binds = {
          "Mod+Grave".focus-workspace = lib.mkForce "void";
          "Mod+Shift+Grave".move-column-to-workspace = lib.mkForce "void";
        };
      };

      prefs = {
        user = {
          name = "pango";
          displayName = "pango";
        };

        timeZone = "America/Toronto";
      };
    };

  flake.nixosConfigurations = self.mkConfigurations "pango" (
    with self.nixosModules;
    {
      normal.include = [ pango ];
      iso.include = [ vm-monitor ];
    }
  );
}
