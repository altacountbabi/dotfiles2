{ self, inputs, ... }:

{
  flake.nixosConfigurations.depozit = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      (
        { lib, ... }:
        {
          imports = lib.mkHost (
            with self.nixosModules;
            {
              profile = self.profiles.server;
              include = [
                iso
                depozitHardware
              ];
            }
          );

          prefs.network.hostname = "depozit";

          prefs.git.user = {
            name = "Whoman";
            email = "altacountbabi@users.noreply.github.com";
          };

          prefs.timeZone = "Europe/Bucharest";
          prefs.language.secondary = "ro_RO.UTF-8";
        }
      )
    ];
  };
}
