# Depracated, the intended way to build ISOs now is by defining `{host}` and `{host}Iso`. Hosts must also include a disko config for the installer to be able to install it

{ inputs, self, ... }:

{
  flake.nixosConfigurations.iso = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.nixosModules.isoHost ];
  };
  flake.iso = self.nixosConfigurations.iso.config.system.build.isoImage;

  flake.nixosConfigurations.isoRelease = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.isoHost
      (_: {
        prefs.iso = {
          squashfsCompression = "zstd -Xcompression-level 19";
        };
      })
    ];
  };
  flake.isoRelease = self.nixosConfigurations.isoRelease.config.system.build.isoImage;

  flake.nixosModules.isoHost =
    { lib, ... }:
    {
      imports = lib.mkHost (
        with self.nixosModules;
        {
          profile = self.profiles.desktop;
          include = [
            vm-monitor
            copy-config
            iso
          ];
          exclude = [
            virtualisation
            bluetooth
            printing
            discord
            steam
            sober
            keyd
            zen
          ];
        }
      );

      prefs = {
        nix.localNixpkgs = true;
      };
    };
}
