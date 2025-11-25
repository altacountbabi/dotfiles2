{ self, ... }:

{
  flake.nixosModules = self.mkModule "base" {
    path = "boot";

    opts =
      { mkOpt, types, ... }:
      {
        timeout =
          mkOpt types.int 0
            "Timeout (in seconds) until bootloader boots the default menu item. Use null if the loader menu should be displayed indefinitely.";
      };

    cfg =
      { config, cfg, ... }:
      {
        boot.loader.timeout = cfg.timeout;

        # TODO: Fix systemd-based initrd for ISOs
        boot.initrd.systemd.enable = (config.prefs.iso or null) == null;
      };
  };
}
