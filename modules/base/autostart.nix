{
  flake.nixosModules.base =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib)
        mkIf
        mapAttrs'
        mkOpt
        types
        ;
    in
    {
      options.prefs = {
        autostart = mkOpt (types.attrsOf (
          types.oneOf [
            types.str
            types.path
            types.package
          ]
        )) { } "List of programs to start once a graphical session begins.";
      };

      config = mkIf (config.prefs.autostart != [ ]) {
        systemd.user.services =
          config.prefs.autostart
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
                  ExecStart =
                    if builtins.isPath value || builtins.isString value then toString value else lib.getExe value;
                  Restart = "on-failure";
                  Type = "simple";
                };
              };
            }
          );
      };
    };
}
