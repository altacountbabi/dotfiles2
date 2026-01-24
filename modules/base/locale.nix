{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    opts =
      {
        config,
        mkOpt,
        types,
        ...
      }:
      {
        language = {
          primary = mkOpt (types.nullOr types.str) "en_US.UTF-8" "The primary language to use in the system";
          secondary =
            mkOpt (types.nullOr types.str) config.prefs.language.primary
              "The secondary language to use in the system, used for things such as time";
        };
      };

    cfg =
      { cfg, lib, ... }:
      {
        i18n =
          let
            inherit (cfg.language) primary secondary;
          in
          {
            defaultLocale = primary;
            extraLocaleSettings =
              lib.genAttrs [
                "LC_NUMERIC"
                "LC_COLLATE"
                "LC_TIME"
                "LC_MONETARY"
                "LC_ADDRESS"
                "LC_IDENTIFICATION"
                "LC_MEASUREMENT"
                "LC_PAPER"
                "LC_TELEPHONE"
                "LC_NAME"
              ] (_: secondary)
              |> lib.mkIf (secondary != null);
          };
      };
  };
}
