{ inputs, ... }:

{
  flake.nixosModules.base =
    { pkgs, lib, ... }:
    let
      inherit (lib) mkOpt types;
    in
    {
      options.prefs = {
        apps.helium = {
          package =
            mkOpt types.package inputs.helium.defaultPackage.${pkgs.stdenv.hostPlatform.system}
              "The package to use for helium browser";
          autostart = mkOpt types.bool false "Whether to automatically start helium browser at startup";
        };
      };
    };

  flake.nixosModules.helium =
    {
      config,
      lib,
      ...
    }:
    {
      environment.systemPackages = [
        config.prefs.apps.helium.package
      ];

      xdg.mime.defaultApplications = lib.mkIf (config.prefs.defaultApps.browser == "helium") (
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
        |> lib.genAttrs (_: "helium.desktop")
      );

      prefs.autostart.helium = lib.mkIf config.prefs.apps.helium.autostart config.prefs.apps.helium.package;
    };
}
