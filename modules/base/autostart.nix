{ self, ... }:

{
  flake.nixosModules = self.mkModule "base" {
    path = "autostart";

    opts =
      { mkOpt, types, ... }:
      mkOpt (types.attrsOf (
        types.oneOf [
          types.str
          types.path
          types.package
        ]
      )) { } "List of programs to start once a graphical session begins.";

    cfg =
      { cfg, lib, ... }:
      let
        inherit (lib) mapAttrs' getExe;
        inherit (builtins) isPath isString;
      in
      {
        systemd.user.services =
          cfg
          |> mapAttrs' (
            name: value: {
              name = "autostart-${name}";
              value = {
                description = "Autostart service for ${name}";
                wantedBy = [ "graphical-session.target" ];
                after = [ "graphical-session.target" ];
                partOf = [ "graphical-session.target" ];
                requisite = [ "graphical-session.target" ];
                serviceConfig = {
                  ExecStart = if isPath value || isString value then toString value else getExe value;
                  Restart = "on-failure";
                  Type = "simple";
                };
              };
            }
          );
      };
  };
}
