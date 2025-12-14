{ self, ... }:

{
  flake.nixosModules = self.mkModule "base" {
    opts =
      { mkOpt, types, ... }:
      let
        module = mkOpt (types.listOf (
          types.oneOf [
            types.str
            types.path
            types.package
          ]
        )) [ ];
      in
      {
        autostart = module "List of programs to start once a graphical session begins.";
        autostart-shell = module "List of programs to start on shell startup.";
      };
  };
}
