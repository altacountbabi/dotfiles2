{ self, ... }:

{
  flake.nixosModules = self.mkModule "services" {
    opts =
      { mkOpt, types, ... }:
      {
        ports = mkOpt (types.attrsOf types.port) { } "Attribute set of ports used for each service";
      };

    cfg =
      { config, lib, ... }:
      {
        assertions = [
          {
            assertion =
              let
                vals = lib.attrValues config.prefs.ports;
              in
              vals == lib.unique vals;
            message = "Clashing port numbers for services: ${toString config.prefs.ports}";
          }
        ];
      };
  };
}
