{ inputs, self, ... }:

{
  flake.nixosConfigurations.depozit = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ self.nixosModules.depozitHost ];
  };

  flake.nixosModules.depozitHost =
    { ... }:
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

      prefs.network.hostname = "depozit";
    };
}
