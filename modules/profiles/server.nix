{ self, ... }:

{
  flake.nixosModules.server = {
    imports = with self.nixosModules; [
      minimal

      ssh
      git
      jj
    ];
  };
}
