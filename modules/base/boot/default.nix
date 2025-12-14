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
      { cfg, ... }:
      {
        boot = {
          loader.timeout = cfg.timeout;
          kernel.sysctl = {
            "vm.swappiness" = 10;
          };
        };

        boot.initrd.systemd.enable = true;
        system.etc.overlay.enable = true;
        system.nixos-init.enable = true;
      };
  };
}
