{ self, inputs, ... }:

{
  flake.nixosModules = self.mkModule "jellyfin" {
    path = "jellyfin";

    opts =
      { mkOpt, types, ... }:
      {
        encoding = mkOpt types.attrs { } ''
          Encoding settings for jellyfin.
          Refer to <https://github.com/Sveske-Juice/declarative-jellyfin/blob/main/documentation/encoding.md> for documentation.
        '';

        users = mkOpt types.attrs { } ''
          User configuration.
          Refer to <https://github.com/Sveske-Juice/declarative-jellyfin/blob/main/documentation/users.md> for documentation.
        '';
      };

    cfg =
      {
        config,
        cfg,
        ...
      }:
      {
        imports = [ inputs.declarative-jellyfin.nixosModules.default ];

        config =
          let
            ports.jellyfin = 8096;
            subdomain = "https://jellyfin.${config.networking.domain}";
          in
          {
            prefs.ports = ports;

            prefs.caddy.${subdomain} = ''
              reverse_proxy localhost:${toString ports.jellyfin}
            '';

            services.jellyfin.enable = true;
            services.declarative-jellyfin = {
              enable = true;
              serverId = "cb86e9d95ec14b11b772bd43e82b4831";

              system = {
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

              inherit (cfg) encoding;

              users = {
                admin = {
                  mutable = false;
                  password = "123";
                  permissions.isAdministrator = true;
                };
              }
              // cfg.users;

              network = {
                internalHttpPort = ports.jellyfin;
                baseUrl = subdomain;
              };

              branding.customCss = "@import url('https://cdn.jsdelivr.net/gh/loof2736/scyfin@latest/CSS/scyfin-theme.css');";
            };
          };
      };
  };
}
