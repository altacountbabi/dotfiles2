{ self, ... }:

{
  systems = [
    "aarch64-linux"
    "x86_64-linux"
  ];

  flake.mkModule =
    name:
    {
      path ? null,

      opts ? (_: { }),
      cfg ? (_: { }),
    }:
    let
      baseModule =
        {
          config,
          pkgs,
          lib,
          ...
        }:
        let
          pathList = if path == null then [ ] else lib.splitString "." path;
        in
        {
          options.prefs =
            if path == null then
              opts {
                inherit
                  lib
                  config
                  pkgs
                  ;
                inherit (lib) mkOpt mkOpt' types;
              }
            else
              lib.setAttrByPath pathList (opts {
                inherit
                  lib
                  config
                  pkgs
                  ;
                inherit (lib) mkOpt mkOpt' types;
              });
        }
        // (lib.optionalAttrs (name == "base") {
          config = cfg (
            let
              moduleCfg = if path == null then config.prefs else lib.getAttrFromPath pathList config.prefs;
            in
            {
              cfg = moduleCfg;
              inherit config pkgs lib;
            }
          );
        });

      configModule =
        if name != "base" then
          {
            ${name} =
              {
                config,
                pkgs,
                lib,
                ...
              }:
              cfg (
                let
                  pathList = if path == null then [ ] else lib.splitString "." path;
                  moduleCfg = if path == null then config.prefs else lib.getAttrFromPath pathList config.prefs;
                in
                {
                  cfg = moduleCfg;
                  inherit config pkgs lib;
                }
              );
          }
        else
          { };
    in
    { base = baseModule; } // configModule;

  flake.nixosModules = self.mkModule "base" {
    opts =
      {
        lib,
        mkOpt,
        types,
        ...
      }:
      {
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
