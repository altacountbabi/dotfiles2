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

        # TODO: Fix systemd-based initrd for ISOs
        boot.initrd.systemd.enable = config.prefs.iso == null;
      };
    };
}
