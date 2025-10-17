{ inputs, self, ... }:

{
  flake.nixosConfigurations.depozit = inputs.nixpkgs.lib.nixosSystem self {
    modules = [ self.nixosModules.depozitHost ];
  };

  flake.nixosModules.depozitHost =
    { ... }:
    {
      imports = with self.nixosModules; [
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
