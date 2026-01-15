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

      prefs = {
        network.hostname = "pango";

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
