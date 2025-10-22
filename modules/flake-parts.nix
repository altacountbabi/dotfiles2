{
  systems = [
    "aarch64-linux"
    "x86_64-linux"
  ];

  flake.nixosModules.base =
    { lib, ... }:
    let
      inherit (lib) mkOpt types;
    in
    {
      options = {
        root = (mkOpt types.path ../. "Shortcut to the root of the flake") // {
          readOnly = true;
        };
        cleanRoot =
          (mkOpt types.path (lib.cleanSourceWith {
            filter = name: type: (type != "symlink" && name != "result");
            src = ../.;
          }) "Shortcut to the root of the flake")
          // {
            readOnly = true;
          };
      };
    };
}
