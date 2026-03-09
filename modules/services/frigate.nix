{ self, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".services.frigate";

    cfg =
      {
        config,
        lib,
        cfg,
        ...
      }:
      {
        config = lib.mkIf cfg.enable (
          let
            ports.frigate = 8971;
            subdomain = "cam.${config.networking.domain}";
          in
          {
            prefs.ports = ports;

            services.frigate = {
              hostname = subdomain;
            };
          }
        );
      };
  };
}
