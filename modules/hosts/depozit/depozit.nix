{ inputs, self, ... }:

{
  flake.nixosConfigurations.depozit = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ self.nixosModules.depozitHost ];
  };

  flake.nixosModules.depozitHost =
    { config, ... }:
    {
      imports = with self.nixosModules; [
        base
        systemd-boot
        tools
        ssh
        git

        nushell
        helix

        ./_hardware.nix
      ];

      hardware.graphics.enable = true;
      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = false;
        powerManagement.finegrained = false;

        open = false;

        nvidiaSettings = true;

        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };

      prefs.network.hostname = "depozit";
    };
}
