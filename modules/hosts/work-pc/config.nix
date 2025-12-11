{ inputs, self, ... }:

{
  flake.nixosConfigurations.work-pc = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      (
        { config, lib, ... }:
        {
          imports = lib.mkHost (
            with self.nixosModules;
            {
              profile = self.profiles.desktop-simple;
              include = [
                iso
                ./_hardware.nix
              ];
            }
          );

          services.displayManager.autoLogin.enable = true;
          services.displayManager.autoLogin.user = config.prefs.user.name;

          prefs = {
            network.hostname = "work-pc";

            theme.wallpaper = builtins.path { path = ../../../plant.jpg; };

            monitors."Virtual-1" = {
              width = 1920;
              height = 1080;
            };

            timeZone = "Europe/Bucharest";
            language.secondary = "ro_RO.UTF-8";
          };
        }
      )
    ];
  };
}
