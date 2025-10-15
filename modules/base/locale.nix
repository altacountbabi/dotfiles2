{
  flake.nixosModules.base =
    { config, lib, ... }:
    let
      inherit (lib) mkOption types;
    in
    {
      options.prefs = {
        timeZone = mkOption {
          type = types.str;
          default = "Europe/Bucharest";
        };

        language = {
          primary = mkOption {
            type = types.str;
            default = "en_US.UTF-8";
          };

          secondary = mkOption {
            type = types.str;
            default = "ro_RO.UTF-8";
          };
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
            extraLocaleSettings = {
              LC_ALL = secondary;
              LC_CTYPE = secondary;
              LC_NUMERIC = secondary;
              LC_COLLATE = secondary;
              LC_TIME = secondary;
              LC_MESSAGES = secondary;
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
