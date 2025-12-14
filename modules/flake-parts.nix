{ self, inputs, ... }:

{
  systems = [
    "aarch64-linux"
    "x86_64-linux"
  ];

  flake.mkConfigurations =
    name:
    {
      system ? "x86_64-linux",
      normal ? {
        include = { };
        exclude = { };
      },
      iso ? {
        include = { };
        exclude = { };
      },
    }:
    let
      lib = inputs.nixpkgs.lib;
      normalModules = normal.include |> lib.subtractLists (normal.exclude or [ ]);
    in
    {
      "${name}" = lib.nixosSystem {
        ${if system != null then "system" else null} = system;
        modules = normalModules;
      };
      "${name}Iso" = lib.nixosSystem {
        ${if system != null then "system" else null} = system;
        modules =
          (normalModules ++ iso.include ++ [ self.nixosModules.iso ])
          |> lib.subtractLists (iso.exclude or [ ]);
      };
    };

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
                inherit (lib)
                  mkOpt
                  mkOpt'
                  mkOption
                  mkConst
                  types
                  ;
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
        mkConst,
        ...
      }:
      {
        root = mkConst (
          lib.cleanSourceWith {
            filter = name: type: (type != "symlink" && name != "result");
            src = ../.;
          }
        );
        rootWithGit = mkConst (
          lib.cleanSourceWith {
            filter = name: type: (type != "symlink" && name != "result") || name == ".git";
            src = ../.;
          }
        );
      };
  };
}
