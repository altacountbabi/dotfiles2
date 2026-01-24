{ self, inputs, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".programs.zen";

    opts =
      {
        pkgs,
        mkOpt,
        types,
        ...
      }:
      {
        enable = mkOpt types.bool false "Enable zen browser";
        package =
          mkOpt types.package inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
            "Zen package";
        autostart = mkOpt types.bool false "Whether to automatically start zen browser at startup";
      };

    cfg =
      {
        config,
        lib,
        cfg,
        ...
      }:
      {
        config = lib.mkIf cfg.enable {
          environment.systemPackages = [
            cfg.package
          ];

          xdg.mime.defaultApplications =
            lib.genAttrs [
              "text/html"
              "application/xhtml+xml"
              "application/x-extension-html"
              "application/x-extension-htm"
              "application/x-extension-shtml"
              "x-scheme-handler/http"
              "x-scheme-handler/https"
              "image/svg+xml"
              "application/pdf"
            ] (_: "zen.desktop")
            |> lib.mkIf (config.prefs.defaultApps.browser == "zen");

          prefs.autostart = lib.mkIf cfg.autostart [ cfg.package ];
        };
      };
  };
}
