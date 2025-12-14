{ self, ... }:

{
  flake.nixosModules = self.mkModule "sonarr" {
    path = "sonarr";

    opts =
      { mkOpt, types, ... }:
      {

      };

    cfg =
      { config, cfg, ... }:
      let
        ports.sonarr = 8989;
        subdomain = "https://sonarr.${config.networking.domain}";
      in
      {
        prefs.ports = ports;

        prefs.caddy.${subdomain} = ''
          reverse_proxy localhost:${toString ports.sonarr}
        '';

        services.sonarr = {
          enable = true;
          settings.server = {
            urlbase = subdomain;
            bindaddress = "*";
            inherit (ports) sonarr;
          };
        };
      };
  };
}
