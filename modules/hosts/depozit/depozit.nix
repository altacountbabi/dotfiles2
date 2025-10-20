{ inputs, self, ... }:

{
  flake.nixosConfigurations.depozit = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.nixosModules.depozitHost ];
  };

  flake.nixosModules.depozitHost =
    { ... }:
    {
      imports = with self.nixosModules; [
        server
        ./_hardware.nix
      ];

      prefs.network.hostname = "depozit";

      prefs.git.user = {
        name = "altacountbabi";
        email = "altacountbabi@users.noreply.github.com";
      };
    };
}
