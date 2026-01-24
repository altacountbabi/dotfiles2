{
  flake.nixosModules.base =
    { config, lib, ... }:
    {
      boot = lib.mkIf config.boot.plymouth.enable {
        consoleLogLevel = 0;
        initrd.verbose = false;
        kernelParams = [
          "loglevel=3"
          "quiet"
          "splash"

          "rd.systemd.show_status=false"
          "rd.udev.log_level=3"
          "udev.log_priority=3"
        ];
      };
    };
}
