{ inputs, self, ... }:

{
  flake.nixosConfigurations.iso = inputs.nixpkgs.lib.nixosSystem self {
    modules = [ self.nixosModules.isoHost ];
  };
  flake.iso = self.nixosConfigurations.iso.config.system.build.isoImage;

  flake.nixosConfigurations.isoRelease = inputs.nixpkgs.lib.nixosSystem self {
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
    { config, lib, ... }:
    {
      imports = with self.nixosModules; [
        systemd-boot
        plymouth
        tools

        nushell
        helix

        niri
        sddm
        sddm-silent

        zen

        iso # Module which provides `system.build.isoImage`
      ];

      prefs.nix.localNixpkgs = true;

      prefs.monitors."Virtual-1" = {
        width = 1920;
        height = 1080;
      };

      # Copy config to user's home directory
      system.activationScripts.copy-config.text =
        let
          src = lib.cleanSourceWith {
            filter = name: type: (type != "symlink" && name != "result");
            src = ../..;
          };
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
