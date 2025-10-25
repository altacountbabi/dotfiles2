{
  flake.nixosModules.base =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib) mkOpt types;
    in
    {
      options.prefs = {
        boot.timeout =
          mkOpt types.int 0
            "Timeout (in seconds) until bootloader boots the default menu item. Use null if the loader menu should be displayed indefinitely.";
      };

      config = {
        boot.loader.timeout = config.prefs.boot.timeout;

        # TODO: Fix systemd-based initrd for ISOs
        boot.initrd.systemd.enable = (config.prefs.iso or null) == null;
      };
    };
}
