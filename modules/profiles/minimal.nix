{ self, ... }:

{
  flake.nixosModules.minimal = {
    imports = with self.nixosModules; [
      bootable

      tools
      nushell
      helix
    ];
  };
}
