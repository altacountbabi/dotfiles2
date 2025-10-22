{
  flake.nixosModules.base =
    { config, lib, ... }:
    let
      inherit (lib) mkIf mkOpt types;
    in
    {
      options.prefs = {
        timeZone = mkOpt (types.nullOr types.str) null ''
          The time zone used when displaying times and dates.
          If null, the timezone will default to UTC and can be set imperatively
        '';

        language = {
          primary = mkOpt (types.nullOr types.str) "en_US.UTF-8" "The primary language to use in the system";
          secondary =
            mkOpt (types.nullOr types.str) null
              "The secondary language to use in the system, used for things such as time";
        };
      };

      config = {
        time.timeZone = config.prefs.timeZone;

        i18n =
          let
            inherit (config.prefs.language) primary secondary;
          in
          {
            defaultLocale = primary;
            extraLocaleSettings = mkIf (secondary != null) {
              LC_NUMERIC = secondary;
              LC_COLLATE = secondary;
              LC_TIME = secondary;
              LC_MONETARY = secondary;
              LC_ADDRESS = secondary;
              LC_IDENTIFICATION = secondary;
              LC_MEASUREMENT = secondary;
              LC_PAPER = secondary;
              LC_TELEPHONE = secondary;
              LC_NAME = secondary;
            };
          };
      };
    };
}
