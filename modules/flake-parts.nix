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
      normal ? { },
      iso ? { },
    }:
    let
      lib = inputs.nixpkgs.lib;
      normalModules = [
        self.nixosModules.base
        normal
        { networking.hostName = name; }
      ];
    in
    {
      "${name}" = lib.nixosSystem {
        inherit system;
        modules = normalModules;
      };
      "${name}Iso" = lib.nixosSystem {
        inherit system;
        modules = normalModules ++ [
          iso
          {
            prefs.iso.enable = true;
            programs.installer.enable = true;
          }
        ];
      };
    };

  flake.mkModule =
    {
      path ? null,
      opts ? (_: { }),
      cfg ? (_: { }),
    }:
    {
      base =
        {
          modulesPath,
          config,
          pkgs,
          lib,
          ...
        }:
        let
          inherit (lib)
            splitString
            hasPrefix
            removePrefix
            getAttrFromPath
            setAttrByPath
            optionalAttrs
            ;

          args = {
            inherit
              modulesPath
              config
              pkgs
              lib
              ;
            inherit (lib)
              mkOpt
              mkOpt'
              mkOption
              mkConst
              types
              ;
          };

          # Normalize path once
          normPath =
            if path == null then
              null
            else
              let
                clean =
                  if hasPrefix "." path then
                    splitString "." (removePrefix "." path)
                  else
                    [ "prefs" ] ++ splitString "." path;
              in
              clean;

          cfgValue = cfg (
            {
              cfg = if normPath == null then config.prefs else getAttrFromPath normPath config;
            }
            // args
          );

          hasConfigKey = lib.hasAttr "config" cfgValue;
        in
        {
          options = if normPath == null then { prefs = opts args; } else setAttrByPath normPath (opts args);

          ${if !hasConfigKey then "config" else null} = cfgValue;
        }
        // optionalAttrs hasConfigKey cfgValue;
    };

  flake.nixosModules.base =
    { lib, ... }:
    {
      options = {
        root = lib.mkConst (
          lib.cleanSourceWith {
            filter = name: type: (type != "symlink" && name != "result");
            src = ../.;
          }
        );
        rootWithGit = lib.mkConst (
          lib.cleanSourceWith {
            filter = name: type: (type != "symlink" && name != "result") || name == ".git";
            src = ../.;
          }
        );
      };
    };
}
