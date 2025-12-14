{ self, inputs, ... }:

{
  flake.nixosModules = self.mkModule "zen" {
    path = "apps.zen";

    opts =
      {
        pkgs,
        mkOpt,
        types,
        ...
      }:
      {
        package =
          mkOpt types.package inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
            "The package to use for zen browser";
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
        environment.systemPackages = [
          cfg.package
        ];

        xdg.mime.defaultApplications = lib.mkIf (config.prefs.defaultApps.browser == "zen") (
          [
            "text/html"
            "application/xhtml+xml"
            "application/x-extension-html"
            "application/x-extension-htm"
            "application/x-extension-shtml"
            "x-scheme-handler/http"
            "x-scheme-handler/https"
            "image/svg+xml"
            "application/pdf"
          ]
          |> lib.genAttrs (_: "zen.desktop")
        );

        prefs.autostart = lib.mkIf cfg.autostart [ cfg.package ];
      };
  };
}
