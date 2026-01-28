{ self, inputs, ... }:

{
  flake.nixosModules = self.mkModule {
    path = ".programs.helium";

    opts =
      {
        pkgs,
        mkOpt,
        types,
        ...
      }:
      {
        enable = mkOpt types.bool false "Enable helium";
        package =
          mkOpt types.package inputs.helium.defaultPackage.${pkgs.stdenv.hostPlatform.system}
            "Helium package";
        autostart = mkOpt types.bool false "Whether to start helium at startup";

        settings = mkOpt (types.attrsOf (pkgs.formats.json { }).type) { } ''
          Helium settings.
          Written to the `Preferences` file of the `Default` profile.
        '';
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
          programs.helium.settings = {
            browser.custom_chrome_frame = lib.mkDefault false;
          };

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
            ] (_: "helium.desktop")
            |> lib.mkIf (config.prefs.defaultApps.browser == "helium");

          prefs.autostart = lib.mkIf cfg.autostart [
            cfg.package
          ];

          prefs.merged-configs.helium = {
            path = "${config.prefs.user.home}/.config/net.imput.helium/Default/Preferences";
            overlay = cfg.settings;
          };
        };
      };
  };
}
