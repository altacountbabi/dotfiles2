{ inputs, ... }:

{
  flake.nixosModules.base =
    { pkgs, lib, ... }:
    let
      inherit (lib) mkOpt types;
    in
    {
      options.prefs = {
        apps.zen = {
          package =
            mkOpt types.package inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
              "The package to use for zen browser";
          autostart = mkOpt types.bool false "Whether to automatically start zen browser at startup";
        };
      };
    };

  flake.nixosModules.zen =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib) mkIf;
    in
    {
      environment.systemPackages = [
        config.prefs.apps.zen.package
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

      prefs.autostart.zen = mkIf config.prefs.apps.zen.autostart config.prefs.apps.zen.package;
    };
}
