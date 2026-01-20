{ self, inputs, ... }:

{
  flake.nixosModules = self.mkModule "helium" {
    path = "apps.helium";

    opts =
      {
        pkgs,
        mkOpt,
        types,
        ...
      }:
      {
        package =
          mkOpt types.package inputs.helium.defaultPackage.${pkgs.stdenv.hostPlatform.system}
            "The package to use for helium browser";
        autostart = mkOpt types.bool false "Whether to automatically start helium browser at startup";
      };

    cfg =
      {
        config,
        cfg,
        lib,
        ...
      }:
      {
        environment.systemPackages = [
          cfg.package
        ];

        xdg.mime.defaultApplications = lib.mkIf (config.prefs.defaultApps.browser == "helium") (
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
          ] (_: "helium.desktop")
        );

        prefs.autostart = lib.mkIf cfg.autostart [ cfg.package ];

        prefs.merged-configs.helium = {
          path = "${config.prefs.user.home}/.config/net.imput.helium/Default/Preferences";
          overlay = {
            browser.custom_chrome_frame = false;
          };
          formatting.raw = true;
        };
      };
  };
}
