{ self, inputs, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".services.jellyfin";

    opts =
      { mkOpt, types, ... }:
      {
        settings = mkOpt (types.attrsOf types.anything) { } "Jellyfin settings";
      };

    cfg =
      {
        config,
        lib,
        cfg,
        ...
      }:
      {
        imports = [
          inputs.declarative-jellyfin.nixosModules.default
        ];

        config = lib.mkIf cfg.enable (
          let
            ports.jellyfin = 8096;
            subdomain = "https://jellyfin.${config.networking.domain}";
          in
          {
            prefs.ports = ports;

            prefs.caddy.${subdomain} = ''
              reverse_proxy localhost:${toString ports.jellyfin}
            '';

            services.declarative-jellyfin =
              let
                inherit (lib) mkDefault;
              in
              {
                enable = true;
                serverId = "cb86e9d95ec14b11b772bd43e82b4831";

                system = mkDefault {
                  minResumePct = 2;

                  pluginRepositories = [
                    {
                      content = {
                        Enabled = true;
                        Name = "Jellyfin Stable";
                        Url = "https://repo.jellyfin.org/files/plugin/manifest.json";
                      };
                      tag = "RepositoryInfo";
                    }
                    {
                      content = {
                        Enabled = true;
                        Name = "Intro Skipper";
                        Url = "https://intro-skipper.org/manifest.json";
                      };
                      tag = "RepositoryInfo";
                    }
                  ];

                  trickplayOptions = {
                    enableHwAcceleration = true;
                    enableHwEncoding = true;
                  };
                };

                users = mkDefault {
                  admin = {
                    mutable = false;
                    password = "123";
                    permissions.isAdministrator = true;
                  };
                };

                network = mkDefault {
                  internalHttpPort = ports.jellyfin;
                  baseUrl = subdomain;
                };

                branding.customCss = mkDefault "@import url('https://cdn.jsdelivr.net/gh/loof2736/scyfin@latest/CSS/scyfin-theme.css');";
              }
              // cfg.settings;
          }
        );
      };
  };
}
