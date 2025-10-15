{
  flake.nixosModules.base =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib) mkOption types;
    in
    {
      options.prefs = {
        boot.timeout = mkOption {
          type = types.int;
          default = 0;
        };
      };

      config = {
        boot.loader.timeout = config.prefs.boot.timeout;
      };
    };
}
