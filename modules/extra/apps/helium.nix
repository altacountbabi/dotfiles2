{ inputs, ... }:

{
  flake.nixosModules.helium =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.programs.helium;
      inherit (lib) mkOpt types;
    in
    {
      options.programs.helium = {
        package =
          mkOpt types.package inputs.helium.defaultPackage.${pkgs.stdenv.hostPlatform.system}
            "The package to use for helium";
        autostart = mkOpt types.bool false "Whether to start helium at startup";

        settings = mkOpt (types.attrsOf (pkgs.formats.json { }).type) { } ''
          Helium settings.
          Written to the `Preferences` file of the `Default` profile.
        '';
      };

      config = {
        programs.helium.settings = {
          browser.custom_chrome_frame = lib.mkDefault false;
        };

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
          overlay = cfg.settings;
          formatting.raw = true;
        };
      };
    };
}
