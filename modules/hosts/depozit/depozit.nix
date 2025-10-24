{ inputs, self, ... }:

{
  flake.nixosConfigurations.depozit = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.nixosModules.depozitHost ];
  };

  flake.nixosModules.depozitHost =
    { lib, ... }:
    {
      imports = lib.mkHost (
        with self.nixosModules;
        {
          profile = self.profiles.server;
          include = [
            iso
            ./_hardware.nix
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
    };
}
