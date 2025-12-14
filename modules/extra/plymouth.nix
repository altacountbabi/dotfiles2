{
  flake.nixosModules.plymouth = {
    boot = {
      consoleLogLevel = 0;
      initrd.verbose = false;
      plymouth.enable = true;
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
