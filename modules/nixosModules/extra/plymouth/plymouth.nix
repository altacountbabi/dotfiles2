{
  flake.nixosModules.plymouth =
    { ... }:
    {
      config = {
        boot = {
          consoleLogLevel = 0;
          initrd.verbose = false;
          plymouth.enable = true;
        };
      };
    };
}
