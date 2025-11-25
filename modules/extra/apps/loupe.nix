{ self, ... }:

{
  flake.nixosModules = self.mkModule "loupe" {
    path = "apps.loupe";

    opts =
      {
        pkgs,
        mkOpt,
        types,
        ...
      }:
      {
        package = mkOpt types.package pkgs.loupe "The loupe package";
      };

    cfg =
      {
        config,
        lib,
        cfg,
        ...
      }:
      {
        environment.systemPackages = [ cfg.package ];

        xdg.mime.defaultApplications = lib.mkIf (config.prefs.defaultApps.image == "loupe") {
          "image/png" = "org.gnome.Loupe.desktop";
          "image/bmp" = "org.gnome.Loupe.desktop";
          "image/jpeg" = "org.gnome.Loupe.desktop";
        };
      };
  };
}
