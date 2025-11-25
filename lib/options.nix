final: prev:

{
  mkOpt =
    type: default: description:
    prev.mkOption {
      inherit type default description;
    };
  mkOpt' =
    type: description:
    prev.mkOption {
      inherit type description;
    };

  # mkModule =
  #   {
  #     name,
  #     opts ? (_: { }),
  #     cfg ? (_: { }),
  #   }:
  #   {
  #     config,
  #     lib,
  #     self ? null,
  #     inputs ? null,
  #     pkgs ? null,
  #     ...
  #   }:
  #   let
  #     pathList = lib.splitString "." name;
  #     moduleCfg = lib.getAttrFromPath pathList config.prefs;
  #   in
  #   {
  #     options.prefs = lib.setAttrByPath pathList (opts {
  #       inherit
  #         lib
  #         config
  #         self
  #         inputs
  #         pkgs
  #         ;
  #       inherit (lib) mkOpt mkOpt' types;
  #     });

  #     config = cfg lib moduleCfg;
  #   };
}
