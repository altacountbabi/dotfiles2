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
