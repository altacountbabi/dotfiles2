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
    {
      config,
      lib,
      ...
    }:
    {
      imports = lib.mkHost (
        with self.nixosModules;
        {
          profile = self.profiles.desktop;
          include = [ iso ];
          exclude = [
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

      prefs.theme.wallpaper = "${config.prefs.cleanRoot}/plant.jpg";

      prefs.nix.localNixpkgs = true;

      prefs.monitors."Virtual-1" = {
        width = 1920;
        height = 1080;
      };

      prefs.git.user = {
        name = "altacountbabi";
        email = "altacountbabi@users.noreply.github.com";
      };

      # Copy config to user's home directory
      system.activationScripts.copy-config.text =
        let
          src = config.prefs.cleanRoot;
          username = config.prefs.user.name;
        in
        ''
          mkdir -p /home/${username}
          cp -r ${src} /home/${username}/conf
          chown -R 1000:100 /home/${username}/conf
          chmod +w -R /home/${username}/conf
        '';
    };
}
