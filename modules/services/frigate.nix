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
            ports.frigate = 8000;
            subdomain = "cam.${config.networking.domain}";
          in
          {
            prefs.ports = ports;

            # This is incredibly retarded, frigate relies on nginx, but nginx and caddy can't co-exist on the same port, so we have to reverse proxy nginx:
            # `frigate-web -> nginx:${ports.frigate} -> caddy:443`
            # Hopefully we don't need anything else on port 80
            prefs.caddy.${subdomain} = ''
              reverse_proxy localhost:80
            '';

            services.nginx.virtualHosts.${subdomain}.listen = [
              {
                addr = "127.0.0.1";
                port = ports.frigate;
              }
            ];

            services.frigate = {
              hostname = subdomain;
            };
          }
        );
      };
  };
}
